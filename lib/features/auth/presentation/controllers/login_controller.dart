import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
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

  /// Intenta ingresar. Devuelve `true` si fue exitoso (el router redirige solo).
  Future<bool> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref.read(signInProvider).call(email: email, password: password);
      // Con sesión el router saca al usuario del login: si la pantalla ya se
      // descartó, el notifier también y no hay estado que actualizar.
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } on ApiException catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );
