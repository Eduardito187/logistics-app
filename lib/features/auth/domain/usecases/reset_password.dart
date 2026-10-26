import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

/// Casos de uso del reseteo de contraseña por OTP: pedir el código al correo y
/// cambiar la contraseña con ese código.
class ResetPassword {
  const ResetPassword(this._repo);

  final AuthRepository _repo;

  /// Paso 1: solicita el envío del código (respuesta siempre genérica).
  Future<void> requestCode(String email) => _repo.forgotPassword(email);

  /// Paso 2: cambia la contraseña con el código recibido.
  Future<void> confirm({
    required String email,
    required String code,
    required String password,
  }) => _repo.resetPassword(email: email, code: code, password: password);
}

final resetPasswordProvider = Provider<ResetPassword>(
  (ref) => ResetPassword(ref.watch(authRepositoryProvider)),
);
