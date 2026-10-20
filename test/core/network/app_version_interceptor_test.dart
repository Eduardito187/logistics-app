import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/version/app_build_info.dart';
import 'package:logistics_app/core/version/app_version.dart';
import 'package:logistics_app/core/version/version_gate.dart';

// AppVersionInterceptor (vía dioProvider): cabeceras X-App-Version/X-App-Build
// y lectura de X-Min-App-Version / 426. Transporte falso, sin red.

class _FakeAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Map<String, List<String>> headers = {};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ProviderContainer container;
  late Dio dio;
  late _FakeAdapter adapter;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        appBuildInfoLoaderProvider.overrideWithValue(
          () async => const AppBuildInfo(version: '1.4.2', buildNumber: '42'),
        ),
      ],
    );
    container.read(versionGateProvider);
    await container.read(appBuildInfoProvider.notifier).ensureLoaded();
    adapter = _FakeAdapter();
    dio = container.read(dioProvider)..httpClientAdapter = adapter;
  });

  tearDown(() => container.dispose());

  test('envía X-App-Version y X-App-Build en cada request', () async {
    await dio.get<dynamic>('/app/auth/me');
    final sent = adapter.lastRequest!.headers;
    expect(sent['X-App-Version'], '1.4.2');
    expect(sent['X-App-Build'], '42');
  });

  test('sin versión cargada no envía las cabeceras', () async {
    final c = ProviderContainer(
      overrides: [
        appBuildInfoLoaderProvider.overrideWithValue(
          () async => throw StateError('sin plataforma'),
        ),
      ],
    );
    addTearDown(c.dispose);
    final a = _FakeAdapter();
    final d = c.read(dioProvider)..httpClientAdapter = a;
    await d.get<dynamic>('/app/auth/me');
    expect(a.lastRequest!.headers.containsKey('X-App-Version'), isFalse);
  });

  test('X-Min-App-Version mayor en respuesta 2xx bloquea', () async {
    adapter.headers = {
      'x-min-app-version': ['1.5.0'],
    };
    await dio.get<dynamic>('/app/shipments');
    final gate = container.read(versionGateProvider);
    expect(gate.minRequired, const AppVersion(1, 5));
    expect(gate.mustUpdate, isTrue);
  });

  test('X-Min-App-Version menor no bloquea', () async {
    adapter.headers = {
      'X-Min-App-Version': ['1.0.0'],
    };
    await dio.get<dynamic>('/app/shipments');
    expect(container.read(versionGateProvider).mustUpdate, isFalse);
  });

  test('también se lee en respuestas de error', () async {
    adapter
      ..statusCode = 422
      ..headers = {
        'X-Min-App-Version': ['2.0.0'],
      };
    await expectLater(
      dio.post<dynamic>('/app/deliveries/scans/load'),
      throwsA(isA<DioException>()),
    );
    expect(container.read(versionGateProvider).mustUpdate, isTrue);
  });

  test('426 Upgrade Required bloquea sin cabecera', () async {
    adapter.statusCode = 426;
    await expectLater(
      dio.get<dynamic>('/app/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(container.read(versionGateProvider).mustUpdate, isTrue);
  });

  test('sin cabecera no cambia nada', () async {
    await dio.get<dynamic>('/app/auth/me');
    final gate = container.read(versionGateProvider);
    expect(gate.minRequired, isNull);
    expect(gate.mustUpdate, isFalse);
  });
}
