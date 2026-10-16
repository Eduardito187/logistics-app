import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';

import 'test_fakes.dart';

// TokenStore sobre un almacén seguro falso en memoria. Verifica claves,
// roundtrip de token y la generación estable del deviceId (ULID).

void main() {
  late FakeSecureStorage storage;
  late TokenStore store;

  setUp(() {
    storage = FakeSecureStorage();
    store = TokenStore(storage);
  });

  group('token', () {
    test('readToken devuelve null cuando no hay token guardado', () async {
      expect(await store.readToken(), isNull);
    });

    test('writeToken persiste bajo la clave app_bearer_token', () async {
      await store.writeToken('tok-123');
      expect(storage.data['app_bearer_token'], 'tok-123');
      expect(await store.readToken(), 'tok-123');
    });

    test('writeToken acepta token vacío', () async {
      await store.writeToken('');
      expect(await store.readToken(), '');
    });

    test('writeToken sobreescribe el token anterior', () async {
      await store.writeToken('viejo');
      await store.writeToken('nuevo');
      expect(await store.readToken(), 'nuevo');
    });

    test('clearToken borra el token', () async {
      await store.writeToken('tok');
      await store.clearToken();
      expect(await store.readToken(), isNull);
      expect(storage.data.containsKey('app_bearer_token'), isFalse);
    });

    test('clearToken sin token previo no falla', () async {
      await store.clearToken();
      expect(await store.readToken(), isNull);
    });
  });

  group('deviceId', () {
    test('genera un ULID la primera vez y lo persiste', () async {
      final id = await store.deviceId();
      expect(id, isNotEmpty);
      expect(id.length, 26); // ULID canónico: 26 caracteres Crockford base32.
      expect(storage.data['device_id'], id);
    });

    test('devuelve el mismo id en llamadas sucesivas (estable)', () async {
      final first = await store.deviceId();
      final second = await store.deviceId();
      expect(second, first);
    });

    test('reutiliza el id ya almacenado sin regenerarlo', () async {
      storage.seed('device_id', '01HZZZEXISTINGULIDVALUE000');
      final id = await store.deviceId();
      expect(id, '01HZZZEXISTINGULIDVALUE000');
    });

    test('regenera cuando el id almacenado es cadena vacía', () async {
      storage.seed('device_id', '');
      final id = await store.deviceId();
      expect(id, isNotEmpty);
      expect(id.length, 26);
    });
  });
}
