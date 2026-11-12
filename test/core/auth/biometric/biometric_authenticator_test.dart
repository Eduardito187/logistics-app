import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/biometric/biometric_authenticator.dart';
import 'package:logistics_app/core/auth/biometric/biometric_capabilities.dart';
import 'package:logistics_app/core/auth/biometric/biometric_result.dart';
import 'package:logistics_app/core/auth/biometric/biometric_type.dart';

// Servicio sobre el canal nativo `bo.com.dismac/biometric` con un canal falso:
// contrato de métodos/argumentos y que nunca lance (sin canal → no soportado).

const _channel = MethodChannel(BiometricAuthenticator.channelName);

void _mockChannel(Future<Object?> Function(MethodCall call)? handler) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_channel, handler);
  addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('capabilities', () {
    test('lee el mapa del canal', () async {
      _mockChannel((call) async {
        expect(call.method, 'capabilities');
        return {
          'supported': true,
          'enrolled': true,
          'types': ['fingerprint', 'face'],
          'platformLabel': null,
        };
      });
      final caps = await BiometricAuthenticator().capabilities();
      expect(caps.isAvailable, isTrue);
      expect(caps.types, {BiometricType.fingerprint, BiometricType.face});
    });

    test('soportado sin registrar', () async {
      _mockChannel(
        (call) async => {'supported': true, 'enrolled': false, 'types': []},
      );
      final caps = await BiometricAuthenticator().capabilities();
      expect(caps.supported, isTrue);
      expect(caps.enrolled, isFalse);
    });

    test('sin canal nativo → no soportado (no lanza)', () async {
      _mockChannel(null);
      expect(
        await BiometricAuthenticator().capabilities(),
        BiometricCapabilities.unsupported,
      );
    });

    test('error de plataforma → no soportado', () async {
      _mockChannel((call) async => throw PlatformException(code: 'boom'));
      expect(
        await BiometricAuthenticator().capabilities(),
        BiometricCapabilities.unsupported,
      );
    });

    test('respuesta nula → no soportado', () async {
      _mockChannel((call) async => null);
      expect(
        await BiometricAuthenticator().capabilities(),
        BiometricCapabilities.unsupported,
      );
    });
  });

  group('authenticate', () {
    test('manda motivo y botón de cancelar; mapea cada resultado', () async {
      MethodCall? received;
      var reply = 'success';
      _mockChannel((call) async {
        received = call;
        return reply;
      });
      final auth = BiometricAuthenticator();

      expect(
        await auth.authenticate(reason: 'Ingresá', cancel: 'Usar contraseña'),
        BiometricResult.success,
      );
      expect(received?.method, 'authenticate');
      expect(received?.arguments, {
        'reason': 'Ingresá',
        'cancel': 'Usar contraseña',
      });

      const expected = {
        'cancelled': BiometricResult.cancelled,
        'lockout': BiometricResult.lockout,
        'notEnrolled': BiometricResult.notEnrolled,
        'notAvailable': BiometricResult.notAvailable,
        'failed': BiometricResult.failed,
        'algo_raro': BiometricResult.failed,
      };
      for (final entry in expected.entries) {
        reply = entry.key;
        expect(await auth.authenticate(reason: 'x'), entry.value);
      }
    });

    test('sin canal nativo → notAvailable', () async {
      _mockChannel(null);
      expect(
        await BiometricAuthenticator().authenticate(reason: 'x'),
        BiometricResult.notAvailable,
      );
    });

    test('error de plataforma → notAvailable', () async {
      _mockChannel((call) async => throw PlatformException(code: 'boom'));
      expect(
        await BiometricAuthenticator().authenticate(reason: 'x'),
        BiometricResult.notAvailable,
      );
    });
  });
}
