import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../entities/two_factor_enrollment.dart';
import '../repositories/auth_repository.dart';

/// Casos de uso de administración del 2FA (activar/confirmar/desactivar), que
/// operan sobre la sesión vigente. Se agrupan por ser el mismo flujo (Ajustes ›
/// Seguridad) y compartir el repositorio.
class ManageTwoFactor {
  const ManageTwoFactor(this._repo);

  final AuthRepository _repo;

  /// Paso 1: obtiene el secreto, la URI del QR y los códigos de recuperación.
  Future<TwoFactorEnrollment> enroll() => _repo.enrollTwoFactor();

  /// Paso 2: confirma con un código del autenticador y activa el 2FA.
  Future<void> confirm(String code) => _repo.confirmTwoFactor(code);

  /// Desactiva el 2FA, con código (TOTP/recovery) o con la contraseña actual.
  Future<void> disable({String? code, String? password}) =>
      _repo.disableTwoFactor(code: code, password: password);
}

final manageTwoFactorProvider = Provider<ManageTwoFactor>(
  (ref) => ManageTwoFactor(ref.watch(authRepositoryProvider)),
);
