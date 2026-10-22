import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/sign_in.dart';

/// Controla el estado del formulario de login (cargando / error).
/// Se apoya en el caso de uso [SignIn]; no conoce la API ni el repositorio.
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Intenta ingresar. Devuelve `true` si fue exitoso (el router redirige solo).
  Future<bool> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref.read(signInProvider).call(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stack) {
      // Se atrapa CUALQUIER error (no solo ApiException): si algo inesperado
      // falla, el botón no debe quedar girando para siempre. La pantalla muestra
      // el mensaje (genérico si no es ApiException).
      state = AsyncError(error, stack);
      return false;
    }
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
