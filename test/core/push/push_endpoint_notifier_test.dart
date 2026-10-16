// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/push/push_endpoint_notifier.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Endpoint push persistido en el secure storage. Se mockea el storage con una
// implementación en memoria a través de su PlatformInterface.

class _InMemorySecureStorage extends FlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  final Map<String, String> store = {};

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => store[key];

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => store.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async => Map<String, String>.from(store);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    store.clear();
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _InMemorySecureStorage storage;

  setUp(() {
    storage = _InMemorySecureStorage();
    FlutterSecureStoragePlatform.instance = storage;
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(const FlutterSecureStorage()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('nace en null y carga el endpoint guardado del storage', () async {
    storage.store['push_endpoint'] = 'https://ntfy.sh/guardado';
    final container = makeContainer();

    expect(container.read(pushEndpointProvider), isNull);
    await _flush();
    expect(container.read(pushEndpointProvider), 'https://ntfy.sh/guardado');
  });

  test('un valor vacío en el storage no cambia el estado', () async {
    storage.store['push_endpoint'] = '';
    final container = makeContainer();
    await _flush();
    expect(container.read(pushEndpointProvider), isNull);
  });

  test('save actualiza el estado y persiste', () async {
    final container = makeContainer();
    await _flush();

    await container
        .read(pushEndpointProvider.notifier)
        .save('https://ntfy.sh/nuevo');

    expect(container.read(pushEndpointProvider), 'https://ntfy.sh/nuevo');
    expect(storage.store['push_endpoint'], 'https://ntfy.sh/nuevo');
  });

  test('clear vuelve a null y borra del storage', () async {
    storage.store['push_endpoint'] = 'https://ntfy.sh/x';
    final container = makeContainer();
    await _flush();

    await container.read(pushEndpointProvider.notifier).clear();

    expect(container.read(pushEndpointProvider), isNull);
    expect(storage.store.containsKey('push_endpoint'), isFalse);
  });
}
