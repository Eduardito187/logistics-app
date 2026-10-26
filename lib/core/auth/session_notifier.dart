import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/node.dart';
import '../network/api_exception.dart';
import '../network/auth_headers.dart';
import '../network/dio_client.dart';
import '../offline/sync_maintenance.dart';
import 'session.dart';
import 'token_store.dart';
import 'user_role.dart';

/// Sesión actual. `null` = sin sesión.
///
/// Persistente como en WhatsApp: token + copia de la sesión viven en el
/// almacén seguro, [restore] la recupera al abrir la app (aunque no haya señal)
/// y solo se borra al cerrar sesión o cuando el backend revoca el token (401).
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

  /// Recupera la sesión guardada al abrir la app. Devuelve `true` si quedó
  /// logueado. Sin token, sin copia o con datos corruptos queda sin sesión (va
  /// al login). No toca la red: un token revocado lo detecta el primer 401.
  Future<bool> restore() async {
    final String? token;
    final Map<String, Object?>? snapshot;
    try {
      // En paralelo (salen de memoria si el almacén ya se precargó).
      (token, snapshot) = await (
        _store.readToken(),
        _store.readSessionSnapshot(),
      ).wait;
    } on Object {
      // Almacén ilegible (p. ej. tras restaurar un backup): se pide login.
      return false;
    }
    if (token == null || token.isEmpty || snapshot == null) return false;
    final role = UserRole.values.asNameMap()[snapshot['role']];
    final userName = snapshot['userName'];
    if (role == null || userName is! String) return false;
    final abilities = snapshot['abilities'];
    _headers.setToken(token);
    state = Session(
      userName: userName,
      role: role,
      token: token,
      abilities: abilities is List
          ? abilities.whereType<String>().toList()
          : const [],
      storeNode: _nodeFrom(snapshot['storeNode']),
    );
    return true;
  }

  /// Login contra el backend: guarda el token y lo pone en las cabeceras.
  Future<void> signIn({
    required String token,
    required String userName,
    required UserRole role,
    List<String> abilities = const [],
    Node? storeNode,
  }) async {
    await _store.writeToken(token);
    _headers.setToken(token);
    final session = Session(
      userName: userName,
      role: role,
      token: token,
      abilities: abilities,
      storeNode: storeNode,
    );
    state = session;
    await _persist(session);
  }

  /// Guarda la copia de la sesión real (con token) para [restore].
  Future<void> _persist(Session session) async {
    if (session.token == null) return;
    try {
      await _store.writeSessionSnapshot({
        'userName': session.userName,
        'role': session.role.name,
        'abilities': session.abilities,
        'storeNode': session.storeNode?.toJson(),
      });
    } on Object {
      // Sin copia la sesión sigue en memoria; solo no sobrevivirá un reinicio.
    }
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
    _update(current, abilities: abilities, storeNode: current.storeNode);
  }

  /// Aplica lo que devuelve `/app/auth/me` (abilities + tienda asignada) y lo
  /// persiste. Sin sesión no hace nada.
  void applyProfile({required List<String> abilities, Node? storeNode}) {
    final current = state;
    if (current == null) return;
    _update(current, abilities: abilities, storeNode: storeNode);
  }

  void _update(
    Session current, {
    required List<String> abilities,
    required Node? storeNode,
  }) {
    final updated = Session(
      userName: current.userName,
      role: current.role,
      token: current.token,
      abilities: abilities,
      storeNode: storeNode,
    );
    state = updated;
    unawaited(_persist(updated));
  }

  static Node? _nodeFrom(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    try {
      return Node.fromJson(raw);
    } on Object {
      // Copia vieja/corrupta: sin tienda; `/me` la repone al próximo login.
      return null;
    }
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
        storeNode: current.storeNode,
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
    final bool hadToken;
    try {
      hadToken = state?.token != null;
      // Primero lo que ve el usuario: sin sesión → el router lleva al login AL
      // INSTANTE (antes esperaba hasta 3 s de drenado + 4 s de revocación).
      // El Bearer sigue en las cabeceras para el trabajo de abajo.
      state = null;
      try {
        await (_store.clearToken(), _store.clearSessionSnapshot()).wait;
      } on Object {
        // Se ignora: la sesión en memoria ya se cerró.
      }
    } finally {
      // El guard cubre solo el cierre local. Si alguien vuelve a entrar
      // mientras sigue el trabajo de fondo de abajo, su sesión nueva tiene que
      // poder cerrarse normalmente.
      _closing = false;
    }
    await _afterSignOut(hadToken: hadToken);
  }

  /// Trabajo de fondo del cierre (el usuario ya está en el login). Nunca toca
  /// una sesión nueva que haya entrado mientras tanto.
  Future<void> _afterSignOut({required bool hadToken}) async {
    try {
      // Si había sesión real, se revoca el token en el servidor (best-effort,
      // con tope corto) mientras el usuario ya está en el login.
      if (hadToken) {
        // Política de la cola offline al cerrar sesión:
        // 1. Con el token todavía vigente se intenta subir lo pendiente (tope
        //    corto: nunca traba el cierre). Tras revocar ya no se puede.
        // 2. Lo que no suba queda PENDIENTE en el teléfono y se sube con la
        //    próxima sesión de este dispositivo (los hechos llevan su propio
        //    `occurred_at`, `device_id` e Idempotency-Key). No se borra:
        //    borrarlo perdería escrituras de terreno.
        // 3. Más abajo se limpian los datos que ya no sirven (fallidas ya
        //    reportadas, fotos huérfanas).
        await syncMaintenanceIfOpen(ref)?.drainBeforeSignOut();
        // Si mientras tanto entró otra sesión, las cabeceras ya llevan SU
        // token: revocar ahora la cerraría a ella. El token viejo vence solo.
        if (state == null) {
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
      }
      // Si mientras tanto entró otra sesión, su token no se toca.
      if (state == null) _headers.setToken(null);
      // Datos locales que no son cola pendiente: acciones/fotos `failed` (ya
      // reportadas al FailureReporter) con sus archivos y fotos huérfanas.
      // Best-effort: `clearAfterSignOut` nunca lanza.
      await syncMaintenanceIfOpen(ref)?.clearAfterSignOut();
    } on Object {
      // Best-effort: el cierre local ya ocurrió.
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
