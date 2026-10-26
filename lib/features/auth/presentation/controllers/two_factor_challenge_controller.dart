import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/verify_two_factor.dart';

/// Estado de la pantalla de verificación 2FA (cargando / error). Al verificar
/// con éxito, la sesión se abre y el router redirige solo al inicio.
class TwoFactorChallengeController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Verifica el código (TOTP o recovery). Devuelve `true` si entró.
  Future<bool> verify({
    required String challengeId,
    required String code,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(verifyTwoFactorProvider)
          .call(challengeId: challengeId, code: code);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }
}

final twoFactorChallengeControllerProvider =
    AsyncNotifierProvider<TwoFactorChallengeController, void>(
      TwoFactorChallengeController.new,
    );
