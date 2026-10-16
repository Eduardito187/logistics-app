import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../network/auth_headers.dart';
import '../network/dio_client.dart';
import 'session.dart';
import 'token_store.dart';
import 'user_role.dart';

/// Sesión actual. `null` = sin sesión.
///
/// El login real (usuario+dispositivo → token Sanctum) se conecta cuando el
/// backend exponga ese endpoint (brecha A-02 del roadmap). Mientras tanto queda
/// el dev-login por rol y la infraestructura de token lista para enchufarlo.
class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Guarda contra cierres reentrantes. Un 401 revoca el token con una llamada
  /// de red (`appLogout`) que tarda; mientras está en vuelo, el estado sigue
  /// siendo != null. Sin esta bandera, los 401 que llegan en paralelo (varias
  /// requests fallando casi a la vez) volverían a pasar el guard de
  /// [handleUnauthorized], re-avisarían al usuario y dispararían otra
  /// revocación. Con ella, un solo cierre corre aunque lleguen N 401.
  bool _closing = false;

  TokenStore get _store => ref.read(tokenStoreProvider);
  AuthHeadersNotifier get _headers => ref.read(authHeadersProvider.notifier);

  /// Login contra el backend: guarda el token y lo pone en las cabeceras.
  Future<void> signIn({
    required String token,
    required String userName,
    required UserRole role,
    List<String> abilities = const [],
  }) async {
    await _store.writeToken(token);
    _headers.setToken(token);
    state = Session(
      userName: userName,
      role: role,
      token: token,
      abilities: abilities,
    );
  }

  /// Guarda las abilities del token tras consultar `/app/auth/me`, sin tocar el
  /// resto de la sesión. Se llama después de [signIn] (el Bearer ya está puesto).
  /// Si no hay sesión activa no hace nada. Degradación segura: si `/me` falla no
  /// se invoca y la sesión queda con abilities vacías.
  void setAbilities(List<String> abilities) {
    final current = state;
    if (current == null) {
      return;
    }
    state = Session(
      userName: current.userName,
      role: current.role,
      token: current.token,
      abilities: abilities,
    );
  }

  /// Solo para builds de desarrollo: entra con un rol sin pasar por el backend.
  void devSignIn(UserRole role) {
    state = Session(userName: 'dev.${role.name}', role: role);
  }

  /// Rota el token del dispositivo contra el backend (`/app/auth/refresh`):
  /// emite uno nuevo y revoca el anterior, conservando la sesión. Lanza
  /// [ApiException] si no hay sesión real o falla la renovación.
  Future<void> refreshToken() async {
    final current = state;
    if (current == null || current.token == null) {
      throw const ApiException(
        status: 401,
        title: 'Sin sesión',
        detail: 'No hay una sesión activa para renovar.',
      );
    }
    try {
      final response = await ref.read(logisticsApiProvider).auth.appRefresh();
      await _store.writeToken(response.token);
      _headers.setToken(response.token);
      state = Session(
        userName: current.userName,
        role: current.role,
        token: response.token,
        abilities: current.abilities,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> signOut() async {
    // Un solo cierre a la vez: si ya hay uno en curso (p. ej. por un 401), no se
    // reintenta la revocación ni se repite el trabajo local.
    if (_closing) {
      return;
    }
    _closing = true;
    try {
      // Si hay sesión real, se revoca el token en el servidor (best-effort, con
      // un tope corto para no trabar el cierre si no hay red). El Bearer sigue
      // puesto hasta limpiar las cabeceras abajo.
      if (state?.token != null) {
        try {
          await ref
              .read(logisticsApiProvider)
              .auth
              .appLogout()
              .timeout(const Duration(seconds: 4));
        } on Object {
          // Sin red o error: se cierra igual localmente.
        }
      }
      // El estado local se limpia de forma síncrona: el cierre de sesión nunca
      // debe quedar atrapado por una falla del almacén seguro o de la red.
      _headers.setToken(null);
      state = null;
      try {
        await _store.clearToken();
      } on Exception {
        // Se ignora: el token en memoria ya se borró arriba.
      }
    } finally {
      _closing = false;
    }
  }

  /// Cierre de sesión global ante un 401 (token expirado o revocado).
  ///
  /// Lo dispara el interceptor de Dio. Marca el motivo para que una capa
  /// superior pueda avisar al usuario y delega en [signOut], que es resiliente.
  /// Si ya no hay sesión no hace nada: evita avisos y trabajo redundantes
  /// cuando llegan varios 401 seguidos.
  void handleUnauthorized() {
    // `_closing` cubre el caso de 401 concurrentes: mientras la revocación está
    // en vuelo el estado todavía no es null, así que sin esta condición cada
    // 401 en paralelo volvería a avisar y a cerrar.
    if (state == null || _closing) {
      return;
    }
    ref
        .read(sessionExpiredProvider.notifier)
        .set('Tu sesión expiró, volvé a ingresar.');
    unawaited(signOut());
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);
