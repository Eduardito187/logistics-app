import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/login_result.dart';
import '../../domain/usecases/sign_in.dart';

/// Controla el estado del formulario de login (cargando / error).
/// Se apoya en el caso de uso [SignIn]; no conoce la API ni el repositorio.
///
/// autoDispose: es estado del formulario, no de la sesión. Al salir del login
/// se libera (antes quedaba vivo toda la sesión reteniendo el último error con
/// su stack trace) y al volver tras cerrar sesión arranca limpio.
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
      // Con sesión el router saca al usuario del login: si la pantalla ya se
      // descartó, el notifier también y no hay estado que actualizar.
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } on Object catch (error, stack) {
      // Se atrapa CUALQUIER error (no solo ApiException): si algo inesperado
      // falla, el botón no debe quedar girando para siempre. La pantalla muestra
      // el mensaje (genérico si no es ApiException).
      if (ref.mounted) state = AsyncError(error, stack);
      return null;
    }
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );
