import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_key_store.dart';

// Caché local de claves públicas. Nunca debe romper el escaneo: ante basura o
// ausencia devuelve un mapa vacío; el roundtrip write/read conserva {id: base64}.

/// FlutterSecureStorage en memoria (solo read/write por clave). El resto de la
/// API cae en noSuchMethod y no se usa.
class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> store = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) {
      final key = invocation.namedArguments[#key] as String;
      return Future<String?>.value(store[key]);
    }
    if (invocation.memberName == #write) {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String?;
      if (value == null) {
        store.remove(key);
      } else {
        store[key] = value;
      }
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late _FakeSecureStorage storage;
  late LabelKeyStore keyStore;

  setUp(() {
    storage = _FakeSecureStorage();
    keyStore = LabelKeyStore(storage);
  });

  group('LabelKeyStore.read', () {
    test('devuelve vacío cuando no hay nada guardado', () async {
      expect(await keyStore.read(), isEmpty);
    });

    test('devuelve vacío cuando la caché está vacía (string vacío)', () async {
      storage.store['label_public_keys'] = '';
      expect(await keyStore.read(), isEmpty);
    });

    test('devuelve vacío cuando el JSON está corrupto', () async {
      storage.store['label_public_keys'] = '{no-json';
      expect(await keyStore.read(), isEmpty);
    });

    test('devuelve vacío cuando el JSON no es un objeto', () async {
      storage.store['label_public_keys'] = '[1,2,3]';
      expect(await keyStore.read(), isEmpty);
    });

    test('parsea {id: base64} convirtiendo las claves a int', () async {
      storage.store['label_public_keys'] = jsonEncode(<String, String>{
        '1': 'AAA',
        '2': 'BBB',
      });

      final read = await keyStore.read();

      expect(read, <int, String>{1: 'AAA', 2: 'BBB'});
    });

    test('ignora claves no numéricas y valores no-string', () async {
      storage.store['label_public_keys'] = jsonEncode(<String, dynamic>{
        '1': 'AAA',
        'abc': 'BBB', // clave no entera: se ignora
        '3': 42, // valor no string: se ignora
      });

      expect(await keyStore.read(), <int, String>{1: 'AAA'});
    });
  });

  group('LabelKeyStore.write', () {
    test('persiste las claves como JSON {id: base64}', () async {
      await keyStore.write(<int, String>{1: 'AAA', 2: 'BBB'});

      final raw = storage.store['label_public_keys'];
      expect(jsonDecode(raw!), <String, dynamic>{'1': 'AAA', '2': 'BBB'});
    });

    test('ida y vuelta write -> read conserva el mapa', () async {
      await keyStore.write(<int, String>{7: 'XYZ', 9: 'QRS'});

      expect(await keyStore.read(), <int, String>{7: 'XYZ', 9: 'QRS'});
    });

    test('escribir un mapa vacío y leerlo devuelve vacío', () async {
      await keyStore.write(const <int, String>{});
      expect(await keyStore.read(), isEmpty);
    });
  });
}
