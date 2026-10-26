import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/auth/domain/entities/login_result.dart';
import 'package:logistics_app/features/auth/domain/entities/two_factor_challenge.dart';
import 'package:logistics_app/features/auth/domain/entities/two_factor_enrollment.dart';
import 'package:logistics_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:logistics_app/features/auth/domain/usecases/sign_in.dart';
import 'package:logistics_app/features/auth/presentation/controllers/login_controller.dart';

// LoginController: traduce el caso de uso SignIn a estado de carga/error y
// devuelve el LoginResult (sesión abierta o reto 2FA) o null si falló. No conoce
// la API ni el repositorio (se los inyecta por signInProvider, acá con un
// repositorio falso).

/// Repositorio falso de auth: registra la llamada, opcionalmente espera un
/// `gate` (para observar el estado de carga), devuelve un `result` configurable
/// y opcionalmente lanza un error.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error, this.gate, this.result});

  final Object? error;
  final Completer<void>? gate;
  final LoginResult? result;
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return result ?? const LoginSignedIn();
  }

  @override
  Future<void> verifyTwoFactor({
    required String challengeId,
    required String code,
  }) async {}

  @override
  Future<TwoFactorEnrollment> enrollTwoFactor() => throw UnimplementedError();

  @override
  Future<void> confirmTwoFactor(String code) async {}

  @override
  Future<void> disableTwoFactor({String? code, String? password}) async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {}
}

ProviderContainer _containerWith(_FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [signInProvider.overrideWithValue(SignIn(repo))],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'credenciales ok sin 2FA: devuelve LoginSignedIn y estado AsyncData',
    () async {
      final repo = _FakeAuthRepository();
      final container = _containerWith(repo);

      final result = await container
          .read(loginControllerProvider.notifier)
          .submit(email: 'user@x.com', password: 'secret');

      expect(result, isA<LoginSignedIn>());
      expect(repo.loginCalled, isTrue);
      expect(repo.lastEmail, 'user@x.com');
      expect(repo.lastPassword, 'secret');
      final state = container.read(loginControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
      expect(state, isA<AsyncData<void>>());
    },
  );

  test('con 2FA: devuelve LoginNeedsTwoFactor con el reto', () async {
    const challenge = TwoFactorChallenge(
      challengeId: 'abc',
      expiresInSeconds: 300,
    );
    final container = _containerWith(
      _FakeAuthRepository(result: const LoginNeedsTwoFactor(challenge)),
    );

    final result = await container
        .read(loginControllerProvider.notifier)
        .submit(email: 'user@x.com', password: 'secret');

    expect(result, isA<LoginNeedsTwoFactor>());
    expect((result! as LoginNeedsTwoFactor).challenge.challengeId, 'abc');
  });

  test('401 credenciales inválidas: devuelve null y guarda el error', () async {
    const error = ApiException(
      status: 401,
      title: 'No se pudo ingresar',
      detail: 'Usuario o contraseña incorrectos.',
    );
    final container = _containerWith(_FakeAuthRepository(error: error));

    final result = await container
        .read(loginControllerProvider.notifier)
        .submit(email: 'user@x.com', password: 'mala');

    expect(result, isNull);
    final state = container.read(loginControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, same(error));
  });

  test('422 validación: también devuelve null y guarda el error', () async {
    const error = ApiException(status: 422, title: 'Datos inválidos');
    final container = _containerWith(_FakeAuthRepository(error: error));

    final result = await container
        .read(loginControllerProvider.notifier)
        .submit(email: '', password: '');

    expect(result, isNull);
    expect(container.read(loginControllerProvider).error, same(error));
  });

  test('durante el envío el estado queda en AsyncLoading', () async {
    final gate = Completer<void>();
    final repo = _FakeAuthRepository(gate: gate);
    final container = _containerWith(repo);

    final future = container
        .read(loginControllerProvider.notifier)
        .submit(email: 'user@x.com', password: 'secret');

    // Aún no completó la llamada: el controlador reporta carga.
    expect(container.read(loginControllerProvider).isLoading, isTrue);

    gate.complete();
    final result = await future;
    expect(result, isA<LoginSignedIn>());
    expect(container.read(loginControllerProvider).isLoading, isFalse);
  });

  test('un error inesperado se captura: devuelve null y lo guarda', () async {
    // El controlador atrapa CUALQUIER error (on Object) para no dejar el botón
    // girando: devuelve null y guarda el error, no lo propaga.
    final repo = _FakeAuthRepository(error: StateError('boom'));
    final container = _containerWith(repo);

    final result = await container
        .read(loginControllerProvider.notifier)
        .submit(email: 'user@x.com', password: 'secret');

    expect(result, isNull);
    expect(container.read(loginControllerProvider).error, isA<StateError>());
  });
}
