import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/labels_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/api/models/get_app_labels_public_keys_response.dart';
import 'package:logistics_app/core/api/models/public_key.dart';
import 'package:logistics_app/core/api/models/public_key_bundle.dart';
import 'package:logistics_app/core/labels/label_key_store.dart';
import 'package:logistics_app/core/labels/label_keys_notifier.dart';
import 'package:logistics_app/core/network/dio_client.dart';

// [LabelKeysNotifier] combina claves embebidas + caché + backend con ROTACIÓN
// (unión, nunca reemplazo). En test las embebidas están vacías
// (String.fromEnvironment sin dart-define); se prueban la carga desde caché y
// el refresh contra el backend (éxito, vacío y error -> estado intacto).

/// Caché de claves en memoria (se saltea flutter_secure_storage).
class _FakeKeyStore extends LabelKeyStore {
  _FakeKeyStore([Map<int, String>? seed])
    : data = {...?seed},
      super(const FlutterSecureStorage());

  Map<int, String> data;

  @override
  Future<Map<int, String>> read() async => Map<int, String>.of(data);

  @override
  Future<void> write(Map<int, String> keys) async {
    data = Map<int, String>.of(keys);
  }
}

/// LabelsClient de prueba: getLabelPublicKeys devuelve el bundle inyectado o
/// lanza el error inyectado.
class _FakeLabelsClient implements LabelsClient {
  _FakeLabelsClient({this.bundle, this.error});

  final PublicKeyBundle? bundle;
  final Object? error;

  @override
  Future<GetAppLabelsPublicKeysResponse> getLabelPublicKeys() async {
    if (error != null) throw error!;
    return GetAppLabelsPublicKeysResponse(data: bundle!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeApi extends LogisticsApi {
  _FakeApi(this._labelsClient) : super(Dio());

  final LabelsClient _labelsClient;

  @override
  LabelsClient get labels => _labelsClient;
}

ProviderContainer _container({
  required LabelKeyStore store,
  LogisticsApi? api,
}) {
  final container = ProviderContainer(
    overrides: [
      labelKeyStoreProvider.overrideWithValue(store),
      if (api != null) logisticsApiProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

String _b64(int fill) => base64.encode(List<int>.filled(32, fill));

void main() {
  group('LabelKeysNotifier.build', () {
    test('sin claves embebidas ni caché, arranca vacío', () async {
      final container = _container(store: _FakeKeyStore());

      expect(container.read(labelKeysProvider), isEmpty);
      // Deja correr el microtask de carga de caché: sigue vacío.
      await pumpEventQueue();
      expect(container.read(labelKeysProvider), isEmpty);
    });

    test('fusiona las claves de la caché tras el primer microtask', () async {
      final container = _container(
        store: _FakeKeyStore(<int, String>{1: _b64(1)}),
      );

      // Dispara build() y el microtask _loadCache.
      container.read(labelKeysProvider);
      await pumpEventQueue();

      final state = container.read(labelKeysProvider);
      expect(state.keys, <int>[1]);
      expect(state[1], base64.decode(_b64(1)));
    });

    test('ignora claves corruptas de la caché (base64 inválido)', () async {
      final container = _container(
        store: _FakeKeyStore(<int, String>{1: 'no-base64!!'}),
      );

      container.read(labelKeysProvider);
      await pumpEventQueue();

      expect(container.read(labelKeysProvider), isEmpty);
    });
  });

  group('LabelKeysNotifier.refresh', () {
    test('fusiona las claves del backend y las persiste en caché', () async {
      final store = _FakeKeyStore();
      final api = _FakeApi(
        _FakeLabelsClient(
          bundle: PublicKeyBundle(
            activeKeyId: 2,
            keys: [PublicKey(id: 2, publicKey: _b64(2))],
          ),
        ),
      );
      final container = _container(store: store, api: api);

      container.read(labelKeysProvider);
      await container.read(labelKeysProvider.notifier).refresh();

      final state = container.read(labelKeysProvider);
      expect(state[2], base64.decode(_b64(2)));
      // Se persistió en la caché para el próximo arranque offline.
      expect(await store.read(), <int, String>{2: _b64(2)});
    });

    test(
      'une sin reemplazar: conserva la clave previa y suma la nueva',
      () async {
        final store = _FakeKeyStore(<int, String>{1: _b64(1)});
        final api = _FakeApi(
          _FakeLabelsClient(
            bundle: PublicKeyBundle(
              activeKeyId: 2,
              keys: [PublicKey(id: 2, publicKey: _b64(2))],
            ),
          ),
        );
        final container = _container(store: store, api: api);

        container.read(labelKeysProvider);
        await pumpEventQueue(); // carga la clave 1 de la caché
        await container.read(labelKeysProvider.notifier).refresh();

        final state = container.read(labelKeysProvider);
        expect(state.keys, containsAll(<int>[1, 2]));
        // La caché quedó con la unión de ambas.
        expect(await store.read(), <int, String>{1: _b64(1), 2: _b64(2)});
      },
    );

    test('un bundle vacío no cambia el estado ni la caché', () async {
      final store = _FakeKeyStore();
      final api = _FakeApi(
        _FakeLabelsClient(
          bundle: const PublicKeyBundle(activeKeyId: null, keys: []),
        ),
      );
      final container = _container(store: store, api: api);

      container.read(labelKeysProvider);
      await container.read(labelKeysProvider.notifier).refresh();

      expect(container.read(labelKeysProvider), isEmpty);
      expect(await store.read(), isEmpty);
    });

    test('un error del backend se traga y deja el estado intacto', () async {
      final store = _FakeKeyStore(<int, String>{1: _b64(1)});
      final api = _FakeApi(
        _FakeLabelsClient(
          error: DioException(
            requestOptions: RequestOptions(path: '/app/labels/public-keys'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      final container = _container(store: store, api: api);

      container.read(labelKeysProvider);
      await pumpEventQueue(); // carga la clave 1 de la caché
      await container.read(labelKeysProvider.notifier).refresh();

      // Sigue estando la clave cacheada; el error no la borró.
      expect(container.read(labelKeysProvider).keys, <int>[1]);
    });
  });
}
