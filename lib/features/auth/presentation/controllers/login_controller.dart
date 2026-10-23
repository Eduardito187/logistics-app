import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/login_result.dart';
import '../../domain/usecases/sign_in.dart';

/// Controla el estado del formulario de login (cargando / error).
/// Se apoya en el caso de uso [SignIn]; no conoce la API ni el repositorio.
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Intenta ingresar. Devuelve el [LoginResult] (sesión abierta o reto 2FA) o
  /// `null` si hubo error (la pantalla muestra el mensaje por el listener).
  Future<LoginResult?> submit({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(signInProvider)
          .call(email: email, password: password);
      state = const AsyncData(null);
      return result;
    } on Object catch (error, stack) {
      // Se atrapa CUALQUIER error (no solo ApiException): si algo inesperado
      // falla, el botón no debe quedar girando para siempre. La pantalla muestra
      // el mensaje (genérico si no es ApiException).
      state = AsyncError(error, stack);
      return null;
    }
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
