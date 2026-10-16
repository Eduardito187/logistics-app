import 'package:flutter_test/flutter_test.dart';
// push_status.dart reexporta PushRegistrationState.
import 'package:logistics_app/core/push/push_status.dart';

// Instantánea del estado de push observada por la UI. Se cubren el constructor
// idle, isRegistered y el merge de copyWith.
void main() {
  group('PushRegistrationState', () {
    test('tiene los seis estados del contrato', () {
      expect(PushRegistrationState.values, <PushRegistrationState>[
        PushRegistrationState.idle,
        PushRegistrationState.registering,
        PushRegistrationState.registered,
        PushRegistrationState.unavailable,
        PushRegistrationState.failed,
        PushRegistrationState.unregistered,
      ]);
    });
  });

  group('PushStatus', () {
    test('idle nace sin endpoint ni distribuidor', () {
      const status = PushStatus.idle();
      expect(status.state, PushRegistrationState.idle);
      expect(status.endpoint, isNull);
      expect(status.distributor, isNull);
      expect(status.message, isNull);
      expect(status.isRegistered, isFalse);
    });

    test('isRegistered requiere estado registered Y endpoint no vacío', () {
      const sinEndpoint = PushStatus(state: PushRegistrationState.registered);
      expect(sinEndpoint.isRegistered, isFalse);

      const endpointVacio = PushStatus(
        state: PushRegistrationState.registered,
        endpoint: '',
      );
      expect(endpointVacio.isRegistered, isFalse);

      const ok = PushStatus(
        state: PushRegistrationState.registered,
        endpoint: 'https://ntfy.sh/abc',
      );
      expect(ok.isRegistered, isTrue);
    });

    test('isRegistered es false si el estado no es registered', () {
      const status = PushStatus(
        state: PushRegistrationState.registering,
        endpoint: 'https://ntfy.sh/abc',
      );
      expect(status.isRegistered, isFalse);
    });

    test('copyWith cambia solo lo provisto', () {
      const base = PushStatus(
        state: PushRegistrationState.registering,
        distributor: 'org.ntfy',
      );
      final next = base.copyWith(
        state: PushRegistrationState.registered,
        endpoint: 'https://ntfy.sh/x',
      );
      expect(next.state, PushRegistrationState.registered);
      expect(next.endpoint, 'https://ntfy.sh/x');
      expect(next.distributor, 'org.ntfy'); // conservado
    });

    // FALENCIA DETECTADA (push_status.dart:35-47): copyWith usa `x ?? this.x`,
    // así que no puede limpiar `message` a null. PushController._onNewEndpoint
    // (push_controller.dart:119) llama copyWith(message: null) con la intención
    // de borrar un error previo, pero el mensaje viejo sobrevive.
    test('copyWith(message: null) debería limpiar el mensaje (correcto)', () {
      const conError = PushStatus(
        state: PushRegistrationState.failed,
        message: 'El distribuidor rechazó el registro.',
      );
      final limpio = conError.copyWith(
        state: PushRegistrationState.registered,
        message: null,
      );
      // Comportamiento CORRECTO esperado: el mensaje de error debería borrarse.
      expect(limpio.message, isNull);
    });
  });
}
