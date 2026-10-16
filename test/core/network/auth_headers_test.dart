import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/auth_headers.dart';

// Modelo AuthHeaders (copyWith) y su Notifier (setToken/setDeviceId).

void main() {
  group('AuthHeaders.copyWith', () {
    test('valores por defecto: ambos null', () {
      const h = AuthHeaders();
      expect(h.bearerToken, isNull);
      expect(h.deviceId, isNull);
    });

    test('setea bearerToken conservando deviceId', () {
      const h = AuthHeaders(deviceId: 'dev-1');
      final out = h.copyWith(bearerToken: 'tok');
      expect(out.bearerToken, 'tok');
      expect(out.deviceId, 'dev-1');
    });

    test('setea deviceId conservando bearerToken', () {
      const h = AuthHeaders(bearerToken: 'tok');
      final out = h.copyWith(deviceId: 'dev-1');
      expect(out.bearerToken, 'tok');
      expect(out.deviceId, 'dev-1');
    });

    test(
      'clearToken=true pone bearerToken en null e ignora el parámetro token',
      () {
        const h = AuthHeaders(bearerToken: 'tok', deviceId: 'dev-1');
        final out = h.copyWith(bearerToken: 'nuevo', clearToken: true);
        expect(out.bearerToken, isNull);
        expect(out.deviceId, 'dev-1'); // deviceId se conserva.
      },
    );

    test('copyWith sin argumentos conserva ambos valores', () {
      const h = AuthHeaders(bearerToken: 'tok', deviceId: 'dev-1');
      final out = h.copyWith();
      expect(out.bearerToken, 'tok');
      expect(out.deviceId, 'dev-1');
    });
  });

  group('AuthHeadersNotifier', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    AuthHeaders read() => container.read(authHeadersProvider);
    AuthHeadersNotifier notifier() =>
        container.read(authHeadersProvider.notifier);

    test('estado inicial vacío', () {
      expect(read().bearerToken, isNull);
      expect(read().deviceId, isNull);
    });

    test('setToken con valor agrega el bearer', () {
      notifier().setToken('tok');
      expect(read().bearerToken, 'tok');
    });

    test('setToken(null) limpia el bearer conservando deviceId', () {
      notifier()
        ..setDeviceId('dev-1')
        ..setToken('tok')
        ..setToken(null);
      expect(read().bearerToken, isNull);
      expect(read().deviceId, 'dev-1');
    });

    test('setToken con cadena vacía guarda la cadena vacía (no null)', () {
      notifier().setToken('');
      expect(read().bearerToken, '');
    });

    test('setDeviceId conserva el bearer ya puesto', () {
      notifier()
        ..setToken('tok')
        ..setDeviceId('dev-1');
      expect(read().bearerToken, 'tok');
      expect(read().deviceId, 'dev-1');
    });
  });
}
