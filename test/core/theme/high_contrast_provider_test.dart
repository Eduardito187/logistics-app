import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/theme/high_contrast.dart';

import '../auth/test_fakes.dart';

// Preferencia "Alto contraste (sol)": arranca en false, carga lo guardado en
// segundo plano, persiste los cambios y tolera un almacén roto.

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

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('por defecto está desactivado', () async {
    final container = _container(FakeSecureStorage());
    expect(container.read(highContrastProvider), isFalse);
    await _settle();
    expect(container.read(highContrastProvider), isFalse);
  });

  test('carga el valor guardado', () async {
    final storage = FakeSecureStorage()
      ..seed(HighContrastNotifier.storageKey, 'true');
    final container = _container(storage);
    final sub = container.listen(highContrastProvider, (_, _) {});
    addTearDown(sub.close);
    await _settle();
    expect(container.read(highContrastProvider), isTrue);
  });

  test('set cambia el estado y lo persiste', () async {
    final storage = FakeSecureStorage();
    final container = _container(storage);
    await container.read(highContrastProvider.notifier).set(true);
    expect(container.read(highContrastProvider), isTrue);
    expect(storage.data[HighContrastNotifier.storageKey], 'true');

    await container.read(highContrastProvider.notifier).toggle();
    expect(container.read(highContrastProvider), isFalse);
    expect(storage.data[HighContrastNotifier.storageKey], 'false');
  });

  test('el cambio del usuario gana a una carga lenta', () async {
    final storage = FakeSecureStorage()
      ..seed(HighContrastNotifier.storageKey, 'false');
    final container = _container(storage);
    final sub = container.listen(highContrastProvider, (_, _) {});
    addTearDown(sub.close);
    // Cambio antes de que la carga en segundo plano termine.
    await container.read(highContrastProvider.notifier).set(true);
    await _settle();
    expect(container.read(highContrastProvider), isTrue);
  });

  test('un almacén roto no rompe: queda en default y set igual rige', () async {
    final container = _container(_BrokenStorage());
    final sub = container.listen(highContrastProvider, (_, _) {});
    addTearDown(sub.close);
    await _settle();
    expect(container.read(highContrastProvider), isFalse);
    await container.read(highContrastProvider.notifier).set(true);
    expect(container.read(highContrastProvider), isTrue);
  });
}
