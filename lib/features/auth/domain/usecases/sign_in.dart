import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../entities/login_result.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso (Command, CQRS): inicia sesión con usuario y contraseña.
/// Devuelve el [LoginResult] (sesión abierta o reto 2FA pendiente); propaga
/// `ApiException` ante un error.
class SignIn {
  const SignIn(this._repo);

  final AuthRepository _repo;

  Future<LoginResult> call({
    required String email,
    required String password,
  }) => _repo.login(email: email, password: password);
}

final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);
