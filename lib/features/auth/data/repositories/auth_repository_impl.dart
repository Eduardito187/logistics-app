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
import '../../domain/entities/login_result.dart';
import '../../domain/entities/two_factor_enrollment.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementación del contrato de autenticación. Arma el pedido con el
/// dispositivo, delega la llamada en el data source y, con la respuesta, mapea
/// el rol operativo, abre la sesión y refresca las claves de etiquetas. El
/// cierre de sesión (rol + `/me` + etiquetas) es compartido por el login normal
/// y la verificación de 2FA.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._ref, this._remote);

  final Ref _ref;
  final AuthRemoteDataSource _remote;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _ref.read(tokenStoreProvider).deviceId();
    // Token FCM si ya se registró; viaja como device.push_token para que el
    // backend sepa a dónde notificar.
    final pushToken = _ref.read(pushTokenProvider);

    final LoginRaw raw;
    try {
      raw = await _remote.login(
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

    // El usuario tiene 2FA: todavía no hay sesión, hay que verificar el código.
    final challenge = raw.challenge;
    if (challenge != null) {
      return LoginNeedsTwoFactor(challenge);
    }

    await _completeSignIn(raw.success!);
    return const LoginSignedIn();
  }

  @override
  Future<void> verifyTwoFactor({
    required String challengeId,
    required String code,
  }) async {
    // Un 422 (código inválido/expirado) se propaga tal cual para que la pantalla
    // lo muestre y, si expiró, vuelva al login.
    final response = await _remote.verifyTwoFactor(
      challengeId: challengeId,
      code: code.trim(),
    );
    await _completeSignIn(response);
  }

  @override
  Future<TwoFactorEnrollment> enrollTwoFactor() => _remote.enrollTwoFactor();

  @override
  Future<void> confirmTwoFactor(String code) =>
      _remote.confirmTwoFactor(code.trim());

  @override
  Future<void> disableTwoFactor({String? code, String? password}) =>
      _remote.disableTwoFactor(code: code?.trim(), password: password);

  @override
  Future<void> forgotPassword(String email) =>
      _remote.forgotPassword(email.trim());

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) => _remote.resetPassword(
    email: email.trim(),
    code: code.trim(),
    password: password,
  );

  /// Con la respuesta de éxito (login sin 2FA o verificación OK): resuelve el
  /// rol operativo, abre la sesión, pide abilities (`/me`, degradación segura) y
  /// refresca las claves de etiquetas.
  Future<void> _completeSignIn(AppLoginResponse response) async {
    final role = UserRole.firstOperational(response.user.roles);
    if (role == null) {
      // El usuario existe pero no tiene un rol operativo de terreno.
      throw const NoFieldRoleException();
    }

    final session = _ref.read(sessionProvider.notifier);
    await session.signIn(
      token: response.token,
      userName: response.user.name,
      role: role,
      storeNode: response.user.node,
    );

    // Con el Bearer ya puesto, pedimos las abilities del token (`/app/auth/me`)
    // y las guardamos en la sesión para el gating por permiso. Degradación
    // segura: si `/me` falla (red o permiso) NO rompemos el login; la sesión
    // queda con abilities vacías y la UI cae a filtro solo-rol.
    try {
      final me = await _remote.me();
      session.applyProfile(abilities: me.abilities, storeNode: me.user.node);
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

/// 403 propio de la app: el usuario existe pero no tiene un rol de terreno.
/// A diferencia de un 403 del backend (texto genérico "sin permiso"), acá el
/// motivo es claro y está en español, así que se muestra tal cual.
class NoFieldRoleException extends ApiException {
  const NoFieldRoleException()
    : super(
        status: 403,
        title: 'Sin rol operativo',
        detail:
            'Tu usuario no tiene un rol de terreno asignado. Contactá al '
            'supervisor.',
      );

  @override
  String get message => detail!;
}
