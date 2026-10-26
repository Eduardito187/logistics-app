import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:logistics_app/features/auth/domain/usecases/sign_in.dart';
import 'package:logistics_app/features/auth/presentation/controllers/login_controller.dart';

// LoginController: traduce el caso de uso SignIn a estado de carga/error y a un
// booleano de éxito. No conoce la API ni el repositorio (se los inyecta por el
// provider signInProvider, que acá se override con un repositorio falso).

/// Repositorio falso de auth: registra la llamada, opcionalmente espera un
/// `gate` (para observar el estado de carga) y opcionalmente lanza un error.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error, this.gate});

  final Object? error;
  final Completer<void>? gate;
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }
}

ProviderContainer _containerWith(_FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [signInProvider.overrideWithValue(SignIn(repo))],
  );
  addTearDown(container.dispose);
  // El provider es autoDispose: como en la pantalla, alguien lo escucha
  // mientras dura el formulario.
  container.listen(loginControllerProvider, (_, _) {});
  return container;
}

void main() {
  test('credenciales ok: devuelve true y deja estado en AsyncData', () async {
    final repo = _FakeAuthRepository();
    final container = _containerWith(repo);

    final ok = await container
        .read(loginControllerProvider.notifier)
        .submit(email: 'user@x.com', password: 'secret');

    expect(ok, isTrue);
    expect(repo.loginCalled, isTrue);
    expect(repo.lastEmail, 'user@x.com');
    expect(repo.lastPassword, 'secret');
    final state = container.read(loginControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.isLoading, isFalse);
    expect(state, isA<AsyncData<void>>());
  });

  test(
    '401 credenciales inválidas: devuelve false y guarda el error',
    () async {
      const error = ApiException(
        status: 401,
        title: 'No se pudo ingresar',
        detail: 'Usuario o contraseña incorrectos.',
      );
      final container = _containerWith(_FakeAuthRepository(error: error));

      final ok = await container
          .read(loginControllerProvider.notifier)
          .submit(email: 'user@x.com', password: 'mala');

      expect(ok, isFalse);
      final state = container.read(loginControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    },
  );

  test('422 validación: también devuelve false y guarda el error', () async {
    const error = ApiException(status: 422, title: 'Datos inválidos');
    final container = _containerWith(_FakeAuthRepository(error: error));

    final ok = await container
        .read(loginControllerProvider.notifier)
        .submit(email: '', password: '');

    expect(ok, isFalse);
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
    final ok = await future;
    expect(ok, isTrue);
    expect(container.read(loginControllerProvider).isLoading, isFalse);
  });

  test('un error no-ApiException NO se captura (se propaga)', () async {
    // El controlador solo atrapa ApiException; cualquier otra cosa sube.
    final repo = _FakeAuthRepository(error: StateError('boom'));
    final container = _containerWith(repo);

    await expectLater(
      container
          .read(loginControllerProvider.notifier)
          .submit(email: 'user@x.com', password: 'secret'),
      throwsA(isA<StateError>()),
    );
  });
}
