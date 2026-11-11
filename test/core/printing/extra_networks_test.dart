import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/printing/extra_network_input.dart';
import 'package:logistics_app/core/printing/extra_networks_notifier.dart';

import '../auth/test_fakes.dart';

// Redes extra para buscar impresoras ("Buscar también en otra red"): parseo y
// validación de lo que escribe el usuario, y persistencia en el almacén seguro.

/// Almacén que falla en toda operación (keystore dañado / sin plugin).
class _BrokenStorage implements FlutterSecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<String?>.error(Exception('almacén roto'));
}

ProviderContainer _container(FlutterSecureStorage storage) {
  final container = ProviderContainer(
    overrides: [secureStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

String? _label(String input) => ExtraNetworkInput.parse(input).$1?.label;
String? _error(String input) => ExtraNetworkInput.parse(input).$2;

void main() {
  group('ExtraNetworkInput.parse — válidas', () {
    test('3 octetos -> /24', () {
      expect(_label('192.168.2'), '192.168.2.0/24');
      expect(_label(' 192.168.2. '), '192.168.2.0/24');
    });

    test('red con prefijo explícito', () {
      expect(_label('192.168.2.0/24'), '192.168.2.0/24');
      expect(_label('10.20.0.0/22'), '10.20.0.0/22');
      expect(_label('10.20.0.0/23'), '10.20.0.0/23');
    });

    test('IP completa -> su /24 (y normaliza a la dirección de red)', () {
      expect(_label('192.168.2.154'), '192.168.2.0/24');
      expect(_label('10.20.3.9/22'), '10.20.0.0/22');
    });

    test('válida -> sin error', () {
      expect(_error('192.168.2'), isNull);
    });
  });

  group('ExtraNetworkInput.parse — inválidas', () {
    test('vacía', () {
      expect(_error(''), ExtraNetworkInput.emptyError);
      expect(_error('   '), ExtraNetworkInput.emptyError);
    });

    test('formato', () {
      for (final bad in [
        '192.168',
        '192.168.2.1.5',
        '192.168.300',
        'abc',
        '192.168.2.0/x',
        '192.168.2.0/33',
        '192.168.2.0/24/1',
      ]) {
        expect(_error(bad), ExtraNetworkInput.formatError, reason: bad);
      }
    });

    test('más grande que /22 -> tope', () {
      expect(_error('10.20.0.0/16'), ExtraNetworkInput.tooBigError);
      expect(_error('10.20.0.0/21'), ExtraNetworkInput.tooBigError);
    });

    test('red pública -> rechazada', () {
      expect(_error('8.8.8'), ExtraNetworkInput.publicError);
      expect(_error('172.32.0.0/24'), ExtraNetworkInput.publicError);
    });
  });

  group('ExtraNetworksNotifier', () {
    test('arranca vacío y carga lo guardado', () async {
      final storage = FakeSecureStorage()
        ..seed(
          ExtraNetworksNotifier.storageKey,
          '["192.168.2.0/24","10.20.0.0/22"]',
        );
      final container = _container(storage);

      expect(container.read(extraNetworksProvider), isEmpty);
      final loaded = await container
          .read(extraNetworksProvider.notifier)
          .current();

      expect(loaded.map((n) => n.label), ['192.168.2.0/24', '10.20.0.0/22']);
      expect(container.read(extraNetworksProvider), loaded);
    });

    test('add valida, agrega, no duplica y persiste', () async {
      final storage = FakeSecureStorage();
      final container = _container(storage);
      final notifier = container.read(extraNetworksProvider.notifier);

      expect(await notifier.add('192.168.2'), isNull);
      expect(await notifier.add('192.168.2.0/24'), isNull); // repetida
      expect(await notifier.add('10.20.0.0/16'), ExtraNetworkInput.tooBigError);

      expect(container.read(extraNetworksProvider).map((n) => n.label), [
        '192.168.2.0/24',
      ]);
      expect(
        storage.data[ExtraNetworksNotifier.storageKey],
        '["192.168.2.0/24"]',
      );
    });

    test('remove quita y persiste', () async {
      final storage = FakeSecureStorage()
        ..seed(ExtraNetworksNotifier.storageKey, '["192.168.2.0/24"]');
      final container = _container(storage);
      final notifier = container.read(extraNetworksProvider.notifier);
      final first = (await notifier.current()).single;

      await notifier.remove(first);

      expect(container.read(extraNetworksProvider), isEmpty);
      expect(storage.data[ExtraNetworksNotifier.storageKey], '[]');
    });

    test('lo guardado sobrevive a un contenedor nuevo (reabrir la app)', () async {
      final storage = FakeSecureStorage();
      await _container(
        storage,
      ).read(extraNetworksProvider.notifier).add('192.168.2');

      final reopened = await _container(
        storage,
      ).read(extraNetworksProvider.notifier).current();

      expect(reopened.single.label, '192.168.2.0/24');
    });

    test('almacén roto: queda vacío y add igual rige en memoria', () async {
      final container = _container(_BrokenStorage());
      final notifier = container.read(extraNetworksProvider.notifier);

      expect(await notifier.current(), isEmpty);
      expect(await notifier.add('192.168.2'), isNull);
      expect(container.read(extraNetworksProvider), hasLength(1));
    });

    test('decode ignora JSON corrupto y entradas inválidas', () {
      expect(ExtraNetworksNotifier.decode('no es json'), isEmpty);
      expect(ExtraNetworksNotifier.decode('{"a":1}'), isEmpty);
      expect(
        ExtraNetworksNotifier.decode(
          '["192.168.2.0/24", 5, "8.8.8.0/24", "192.168.2"]',
        ).map((n) => n.label),
        ['192.168.2.0/24'],
      );
    });
  });
}
