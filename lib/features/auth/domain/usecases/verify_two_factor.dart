import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: verifica el código 2FA contra el reto y abre la sesión.
class VerifyTwoFactor {
  const VerifyTwoFactor(this._repo);

  final AuthRepository _repo;

  Future<void> call({required String challengeId, required String code}) =>
      _repo.verifyTwoFactor(challengeId: challengeId, code: code);
}

final verifyTwoFactorProvider = Provider<VerifyTwoFactor>(
  (ref) => VerifyTwoFactor(ref.watch(authRepositoryProvider)),
);
