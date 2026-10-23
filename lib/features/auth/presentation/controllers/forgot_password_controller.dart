import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/reset_password.dart';

/// Estado del flujo "olvidé mi contraseña" (pedir código → cambiar contraseña).
class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Paso 1: pide el código al correo. Siempre "éxito" (respuesta genérica); se
  /// avanza igual al paso del código salvo error de red/validación de formato.
  Future<bool> requestCode(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(resetPasswordProvider).requestCode(email);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }

  /// Paso 2: cambia la contraseña con el código recibido.
  Future<bool> reset({
    required String email,
    required String code,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(resetPasswordProvider)
          .confirm(email: email, code: code, password: password);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }
}

final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, void>(
      ForgotPasswordController.new,
    );
