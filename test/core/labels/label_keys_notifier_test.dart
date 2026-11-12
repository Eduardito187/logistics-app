import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_key_store.dart';
import 'package:logistics_app/core/labels/label_keys_notifier.dart';
import 'package:logistics_app/core/labels/labels_open_mode.dart';
import 'package:logistics_app/core/network/dio_client.dart';

// [LabelKeysNotifier] combina claves embebidas + caché + backend con ROTACIÓN
// (unión, nunca reemplazo). En test las embebidas están vacías
// (String.fromEnvironment sin dart-define); se prueban la carga desde caché y
// el refresh contra el backend (éxito, vacío, error y la señal `open`).
//
// refresh() lee el bundle por Dio CRUDO (el campo `open` no está en el modelo
// generado), así que se mockea un HttpClientAdapter.

/// Caché de claves + flag `open` en memoria (se saltea flutter_secure_storage).
class _FakeKeyStore extends LabelKeyStore {
  _FakeKeyStore([Map<int, String>? seed])
    : data = {...?seed},
      super(const FlutterSecureStorage());

  Map<int, String> data;
  bool open = false;

  @override
  Future<Map<int, String>> read() async => Map<int, String>.of(data);

  @override
  Future<void> write(Map<int, String> keys) async {
    data = Map<int, String>.of(keys);
  }

  @override
  Future<bool> readOpen() async => open;

  @override
  Future<void> writeOpen(bool value) async {
    open = value;
  }
}

/// Adapter de Dio que devuelve un JSON canned para cualquier GET, o lanza un
/// error de conexión.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.json, this.fail = false});

  final String? json;
  final bool fail;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      json!,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _fakeDio({String? json, bool fail = false}) {
  return Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = _FakeAdapter(json: json, fail: fail);
}

/// Bundle JSON como lo manda `GET /app/labels/public-keys`.
String _bundle({
  bool? open,
  int? activeKeyId,
  List<Map<String, Object?>> keys = const [],
}) {
  final data = <String, Object?>{'active_key_id': activeKeyId, 'keys': keys};
  if (open != null) data['open'] = open;
  return jsonEncode({'data': data});
}

ProviderContainer _container({required LabelKeyStore store, Dio? dio}) {
  final container = ProviderContainer(
    overrides: [
      labelKeyStoreProvider.overrideWithValue(store),
      if (dio != null) dioProvider.overrideWithValue(dio),
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
      await pumpEventQueue();
      expect(container.read(labelKeysProvider), isEmpty);
    });

    test('fusiona las claves de la caché tras el primer microtask', () async {
      final container = _container(
        store: _FakeKeyStore(<int, String>{1: _b64(1)}),
      );

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
      final container = _container(
        store: store,
        dio: _fakeDio(
          json: _bundle(
            open: false,
            activeKeyId: 2,
            keys: [
              {'id': 2, 'public_key': _b64(2)},
            ],
          ),
        ),
      );

      container.read(labelKeysProvider);
      await container.read(labelKeysProvider.notifier).refresh();

      final state = container.read(labelKeysProvider);
      expect(state[2], base64.decode(_b64(2)));
      expect(await store.read(), <int, String>{2: _b64(2)});
    });

    test(
      'une sin reemplazar: conserva la clave previa y suma la nueva',
      () async {
        final store = _FakeKeyStore(<int, String>{1: _b64(1)});
        final container = _container(
          store: store,
          dio: _fakeDio(
            json: _bundle(
              activeKeyId: 2,
              keys: [
                {'id': 2, 'public_key': _b64(2)},
              ],
            ),
          ),
        );

        container.read(labelKeysProvider);
        await pumpEventQueue(); // carga la clave 1 de la caché
        await container.read(labelKeysProvider.notifier).refresh();

        final state = container.read(labelKeysProvider);
        expect(state.keys, containsAll(<int>[1, 2]));
        expect(await store.read(), <int, String>{1: _b64(1), 2: _b64(2)});
      },
    );

    test(
      'un bundle sin claves no cambia las claves (pero puede fijar open)',
      () async {
        final store = _FakeKeyStore();
        final container = _container(
          store: store,
          dio: _fakeDio(json: _bundle(open: true, activeKeyId: null)),
        );

        container.read(labelKeysProvider);
        await container.read(labelKeysProvider.notifier).refresh();

        expect(container.read(labelKeysProvider), isEmpty);
        expect(await store.read(), isEmpty);
        // Modo abierto SÍ se fija aunque no haya claves.
        expect(container.read(labelsOpenModeProvider), isTrue);
      },
    );

    test('un error del backend se traga y deja el estado intacto', () async {
      final store = _FakeKeyStore(<int, String>{1: _b64(1)});
      final container = _container(store: store, dio: _fakeDio(fail: true));

      container.read(labelKeysProvider);
      await pumpEventQueue(); // carga la clave 1 de la caché
      await container.read(labelKeysProvider.notifier).refresh();

      expect(container.read(labelKeysProvider).keys, <int>[1]);
    });

    test(
      'open:true fija el modo abierto; open:false lo deja firmado',
      () async {
        final openContainer = _container(
          store: _FakeKeyStore(),
          dio: _fakeDio(json: _bundle(open: true, activeKeyId: 1, keys: [])),
        );
        await openContainer.read(labelKeysProvider.notifier).refresh();
        expect(openContainer.read(labelsOpenModeProvider), isTrue);

        final signedContainer = _container(
          store: _FakeKeyStore(),
          dio: _fakeDio(
            json: _bundle(
              open: false,
              activeKeyId: 1,
              keys: [
                {'id': 1, 'public_key': _b64(1)},
              ],
            ),
          ),
        );
        await signedContainer.read(labelKeysProvider.notifier).refresh();
        expect(signedContainer.read(labelsOpenModeProvider), isFalse);
      },
    );

    test(
      'active_key_id:0 también se toma como modo abierto (defensivo)',
      () async {
        final container = _container(
          store: _FakeKeyStore(),
          dio: _fakeDio(json: _bundle(activeKeyId: 0, keys: [])),
        );
        await container.read(labelKeysProvider.notifier).refresh();
        expect(container.read(labelsOpenModeProvider), isTrue);
      },
    );
  });
}
