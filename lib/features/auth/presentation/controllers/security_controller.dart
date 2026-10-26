import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/two_factor_enrollment.dart';
import '../../domain/usecases/manage_two_factor.dart';
import 'two_factor_status.dart';

/// Controla la pantalla de Seguridad (Ajustes): activar y desactivar el 2FA.
/// El estado async refleja la última operación (cargando / error) para que la
/// pantalla muestre spinners y mensajes; el flag de "2FA activo" vive en
/// [twoFactorEnabledProvider].
class SecurityController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Paso 1 de activación: pide el secreto, la URI del QR y los recovery codes.
  /// Devuelve `null` si falló (el error queda en el estado).
  Future<TwoFactorEnrollment?> enroll() async {
    state = const AsyncLoading();
    try {
      final enrollment = await ref.read(manageTwoFactorProvider).enroll();
      state = const AsyncData(null);
      return enrollment;
    } on Object catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }

  /// Paso 2: confirma con un código del autenticador y activa el 2FA.
  Future<bool> confirm(String code) async {
    state = const AsyncLoading();
    try {
      await ref.read(manageTwoFactorProvider).confirm(code);
      await ref.read(twoFactorEnabledProvider.notifier).set(enabled: true);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }

  /// Desactiva el 2FA con un código (TOTP/recovery).
  Future<bool> disableWithCode(String code) => _disable(code: code);

  /// Desactiva el 2FA con la contraseña actual.
  Future<bool> disableWithPassword(String password) =>
      _disable(password: password);

  Future<bool> _disable({String? code, String? password}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(manageTwoFactorProvider)
          .disable(code: code, password: password);
      await ref.read(twoFactorEnabledProvider.notifier).set(enabled: false);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }
}

final securityControllerProvider =
    AsyncNotifierProvider<SecurityController, void>(SecurityController.new);
