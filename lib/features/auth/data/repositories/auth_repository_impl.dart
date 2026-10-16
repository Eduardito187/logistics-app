import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/auth/token_store.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/labels/label_scanner.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/push/push_controller.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementación del contrato de autenticación. Arma el pedido con el
/// dispositivo, delega la llamada en el data source y, con la respuesta,
/// mapea el rol operativo, abre la sesión y refresca las claves de etiquetas.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._ref, this._remote);

  final Ref _ref;
  final AuthRemoteDataSource _remote;

  @override
  Future<void> login({required String email, required String password}) async {
    final deviceId = await _ref.read(tokenStoreProvider).deviceId();
    // Endpoint de push (UnifiedPush/ntfy) si ya se registró; viaja como
    // device.push_token para que el backend sepa a dónde notificar.
    final pushToken = _ref.read(pushEndpointProvider);

    final AppLoginResponse response;
    try {
      response = await _remote.login(
        AppLoginRequest(
          email: email.trim(),
          password: password,
          device: Device(
            fingerprint: deviceId,
            platform: defaultTargetPlatform.name,
            name: 'App interna',
            pushToken: pushToken,
          ),
        ),
      );
    } on ApiException catch (error) {
      // En login, un 401/422 es "credenciales incorrectas", no sesión caída.
      if (error.status == 401 || error.isValidation) {
        throw const ApiException(
          status: 401,
          title: 'No se pudo ingresar',
          detail: 'Usuario o contraseña incorrectos.',
        );
      }
      rethrow;
    }

    final role = UserRole.firstOperational(response.user.roles);
    if (role == null) {
      // El usuario existe pero no tiene un rol operativo de terreno.
      throw const ApiException(
        status: 403,
        title: 'Sin rol operativo',
        detail: 'Tu usuario no tiene un rol de terreno asignado. Contactá al supervisor.',
      );
    }

    final session = _ref.read(sessionProvider.notifier);
    await session.signIn(
      token: response.token,
      userName: response.user.name,
      role: role,
    );

    // Con el Bearer ya puesto, pedimos las abilities del token (`/app/auth/me`)
    // y las guardamos en la sesión para el gating por permiso. Degradación
    // segura: si `/me` falla (red o permiso) NO rompemos el login; la sesión
    // queda con abilities vacías y la UI cae a filtro solo-rol.
    try {
      final me = await _remote.me();
      session.setAbilities(me.abilities);
    } on ApiException {
      // Sesión sin abilities: la home no oculta nada por permiso (ver regla).
    }

    // Con sesión activa, refrescar las claves públicas de etiquetas (rotación).
    unawaited(_ref.read(labelKeysProvider.notifier).refresh());
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref, ref.watch(authRemoteDataSourceProvider)),
);
