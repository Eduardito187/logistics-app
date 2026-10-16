import 'package:flutter_test/flutter_test.dart';
// push_status.dart reexporta PushRegistrationState.
import 'package:logistics_app/core/push/push_status.dart';

// Instantánea del estado de push (FCM) observada por la UI. Se cubren el
// constructor idle, isRegistered y el merge de copyWith.
void main() {
  group('PushRegistrationState', () {
    test('tiene los cinco estados del contrato', () {
      expect(PushRegistrationState.values, <PushRegistrationState>[
        PushRegistrationState.idle,
        PushRegistrationState.registering,
        PushRegistrationState.registered,
        PushRegistrationState.unavailable,
        PushRegistrationState.failed,
      ]);
    });
  });

  group('PushStatus', () {
    test('idle nace sin token ni mensaje', () {
      const status = PushStatus.idle();
      expect(status.state, PushRegistrationState.idle);
      expect(status.token, isNull);
      expect(status.message, isNull);
      expect(status.isRegistered, isFalse);
    });

    test('isRegistered requiere estado registered Y token no vacío', () {
      const sinToken = PushStatus(state: PushRegistrationState.registered);
      expect(sinToken.isRegistered, isFalse);

      const tokenVacio = PushStatus(
        state: PushRegistrationState.registered,
        token: '',
      );
      expect(tokenVacio.isRegistered, isFalse);

      const ok = PushStatus(
        state: PushRegistrationState.registered,
        token: 'fid-abc',
      );
      expect(ok.isRegistered, isTrue);
    });

    test('isRegistered es false si el estado no es registered', () {
      const status = PushStatus(
        state: PushRegistrationState.registering,
        token: 'fid-abc',
      );
      expect(status.isRegistered, isFalse);
    });

    test('copyWith cambia solo lo provisto', () {
      const base = PushStatus(
        state: PushRegistrationState.registering,
        message: 'aviso',
      );
      final next = base.copyWith(
        state: PushRegistrationState.registered,
        token: 'fid-x',
      );
      expect(next.state, PushRegistrationState.registered);
      expect(next.token, 'fid-x');
      expect(next.message, 'aviso'); // conservado
    });

    test('copyWith(message: null) limpia el mensaje de error previo', () {
      const conError = PushStatus(
        state: PushRegistrationState.failed,
        message: 'Permiso de notificaciones denegado.',
      );
      final limpio = conError.copyWith(
        state: PushRegistrationState.registered,
        token: 'fid-ok',
        message: null,
      );
      expect(limpio.message, isNull);
      expect(limpio.isRegistered, isTrue);
    });
  });
}
