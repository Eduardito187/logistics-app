import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/execution_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/api/models/label_verification.dart';
import 'package:logistics_app/core/api/models/label_verification_result.dart';
import 'package:logistics_app/core/api/models/post_app_labels_verify_response.dart';
import 'package:logistics_app/core/api/models/verify_label_request.dart';
import 'package:logistics_app/core/labels/label_format_exception.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/labels/signed_label.dart';
import 'package:logistics_app/core/network/api_exception.dart';

// Camino de escaneo de [LabelScanner]: verificación offline (la que decide) y
// el reporte best-effort al backend. label_scanner_backend_test.dart ya cubre
// buildVerifyRequest/encodeSignature; aquí van scan, scanAndReport,
// verifyWithBackend y el contraste offline vs backend.

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

LabelVerifier _vectorVerifier() {
  final vector = _vector();
  return LabelVerifier({
    vector['key_id'] as int: base64.decode(
      vector['public_key_base64'] as String,
    ),
  });
}

/// ExecutionClient de prueba: solo implementa verifyLabel; el resto cae en
/// noSuchMethod (nunca se llama en estos tests).
class _FakeExecutionClient implements ExecutionClient {
  _FakeExecutionClient(this._handler);

  final Future<PostAppLabelsVerifyResponse> Function(VerifyLabelRequest body)
  _handler;

  VerifyLabelRequest? lastBody;
  int calls = 0;

  @override
  Future<PostAppLabelsVerifyResponse> verifyLabel({
    required VerifyLabelRequest body,
  }) {
    calls++;
    lastBody = body;
    return _handler(body);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// LogisticsApi de prueba que devuelve un ExecutionClient falso.
class _FakeApi extends LogisticsApi {
  _FakeApi(this._fakeExecution) : super(Dio());

  final ExecutionClient _fakeExecution;

  @override
  ExecutionClient get execution => _fakeExecution;
}

/// Notifier de prueba para fijar el estado de claves sin tocar AppConfig ni la
/// caché (evita el microtask de build()).
class _StubKeysNotifier extends LabelKeysNotifier {
  _StubKeysNotifier(this._initial);

  final Map<int, List<int>> _initial;

  @override
  Map<int, List<int>> build() => _initial;
}

ProviderContainer _scannerContainer(Map<int, List<int>> keys) {
  final container = ProviderContainer(
    overrides: [
      labelKeysProvider.overrideWith(() => _StubKeysNotifier(keys)),
      logisticsApiProvider.overrideWithValue(
        _FakeApi(
          _FakeExecutionClient(
            (_) async => _verifyResponse(
              valid: true,
              result: LabelVerificationResult.valid,
            ),
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

PostAppLabelsVerifyResponse _verifyResponse({
  required bool valid,
  required LabelVerificationResult result,
}) => PostAppLabelsVerifyResponse(
  data: LabelVerification(valid: valid, result: result),
);

void main() {
  group('LabelScanner.canVerify', () {
    test('es true con verificador y false sin él', () {
      expect(LabelScanner(_vectorVerifier()).canVerify, isTrue);
      expect(LabelScanner(null).canVerify, isFalse);
    });
  });

  group('LabelScanner.scan (offline, sin red)', () {
    test('devuelve valid para el QR del vector', () async {
      final scanner = LabelScanner(_vectorVerifier());

      final result = await scanner.scan(_vector()['qr_content'] as String);

      expect(result.verification, VerificationResult.valid);
      expect(result.isValid, isTrue);
      expect(result.backendVerification, isNull);
    });

    test('devuelve invalidSignature para el QR alterado del vector', () async {
      final scanner = LabelScanner(_vectorVerifier());

      final result = await scanner.scan(
        _vector()['tampered_qr_content'] as String,
      );

      expect(result.verification, VerificationResult.invalidSignature);
      expect(result.isValid, isFalse);
    });

    test('lanza LabelFormatException si el QR no es una etiqueta', () async {
      final scanner = LabelScanner(_vectorVerifier());

      expect(
        () => scanner.scan('no-es-json'),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('lanza LabelFormatException si no hay claves configuradas', () async {
      final scanner = LabelScanner(null);

      expect(
        () => scanner.scan(_vector()['qr_content'] as String),
        throwsA(isA<LabelFormatException>()),
      );
    });
  });

  group('LabelScanner.scanAndReport', () {
    test('sin cliente API, devuelve solo el resultado offline', () async {
      final scanner = LabelScanner(_vectorVerifier());

      final result = await scanner.scanAndReport(
        _vector()['qr_content'] as String,
      );

      expect(result.isValid, isTrue);
      expect(result.backendVerification, isNull);
    });

    test('con cliente API, adjunta el contrahecheo del backend', () async {
      final execution = _FakeExecutionClient(
        (_) async =>
            _verifyResponse(valid: true, result: LabelVerificationResult.valid),
      );
      final scanner = LabelScanner(_vectorVerifier(), api: _FakeApi(execution));

      final result = await scanner.scanAndReport(
        _vector()['qr_content'] as String,
      );

      expect(result.isValid, isTrue);
      expect(result.backendVerification, isNotNull);
      expect(result.backendVerification!.valid, isTrue);
      expect(execution.calls, 1);
      // El cuerpo reportado es el canónico exacto y el keyId del QR.
      expect(execution.lastBody!.payload, _vector()['canonical']);
      expect(execution.lastBody!.keyId, _vector()['key_id']);
    });

    test(
      'offline manda: offline valid + backend invalid no cambia isValid',
      () async {
        final execution = _FakeExecutionClient(
          (_) async => _verifyResponse(
            valid: false,
            result: LabelVerificationResult.invalidSignature,
          ),
        );
        final scanner = LabelScanner(
          _vectorVerifier(),
          api: _FakeApi(execution),
        );

        final result = await scanner.scanAndReport(
          _vector()['qr_content'] as String,
        );

        // La decisión en terreno es la offline (valid); el backend solo informa.
        expect(result.isValid, isTrue);
        expect(result.backendVerification!.valid, isFalse);
        expect(
          result.backendVerification!.result,
          LabelVerificationResult.invalidSignature,
        );
      },
    );

    test(
      'si el backend falla (sin red), se ignora y queda el offline',
      () async {
        final execution = _FakeExecutionClient(
          (_) async => throw DioException(
            requestOptions: RequestOptions(path: '/app/labels/verify'),
            type: DioExceptionType.connectionError,
          ),
        );
        final scanner = LabelScanner(
          _vectorVerifier(),
          api: _FakeApi(execution),
        );

        final result = await scanner.scanAndReport(
          _vector()['qr_content'] as String,
        );

        expect(result.isValid, isTrue);
        expect(result.backendVerification, isNull);
      },
    );

    test('propaga LabelFormatException antes de tocar la red', () async {
      final execution = _FakeExecutionClient(
        (_) async =>
            _verifyResponse(valid: true, result: LabelVerificationResult.valid),
      );
      final scanner = LabelScanner(_vectorVerifier(), api: _FakeApi(execution));

      expect(
        () => scanner.scanAndReport('no-es-json'),
        throwsA(isA<LabelFormatException>()),
      );
      expect(execution.calls, 0);
    });
  });

  group('LabelScanner.verifyWithBackend', () {
    test('devuelve el veredicto del backend', () async {
      final execution = _FakeExecutionClient(
        (_) async =>
            _verifyResponse(valid: true, result: LabelVerificationResult.valid),
      );
      final scanner = LabelScanner(_vectorVerifier(), api: _FakeApi(execution));
      final label = SignedLabel.fromQrContent(
        _vector()['qr_content'] as String,
      );

      final backend = await scanner.verifyWithBackend(label);

      expect(backend.valid, isTrue);
      expect(backend.result, LabelVerificationResult.valid);
    });

    test('convierte un DioException en ApiException', () async {
      final execution = _FakeExecutionClient(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/app/labels/verify'),
          response: Response(
            requestOptions: RequestOptions(path: '/app/labels/verify'),
            statusCode: 500,
          ),
        ),
      );
      final scanner = LabelScanner(_vectorVerifier(), api: _FakeApi(execution));
      final label = SignedLabel.fromQrContent(
        _vector()['qr_content'] as String,
      );

      await expectLater(
        scanner.verifyWithBackend(label),
        throwsA(isA<ApiException>()),
      );
    });

    test('lanza StateError si el scanner no tiene cliente API', () async {
      final scanner = LabelScanner(_vectorVerifier());
      final label = SignedLabel.fromQrContent(
        _vector()['qr_content'] as String,
      );

      await expectLater(
        scanner.verifyWithBackend(label),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('labelScannerProvider', () {
    test('con al menos una clave de 32 bytes, el scanner puede verificar', () {
      final container = _scannerContainer({1: List<int>.filled(32, 1)});

      expect(container.read(labelScannerProvider).canVerify, isTrue);
    });

    test('filtra las claves que no miden 32 bytes', () {
      // Hay una clave válida (32) y una inválida (10): el scanner igual puede
      // verificar porque la válida pasa el filtro.
      final container = _scannerContainer({
        1: List<int>.filled(32, 1),
        2: List<int>.filled(10, 0),
      });

      expect(container.read(labelScannerProvider).canVerify, isTrue);
    });

    test('sin ninguna clave de 32 bytes, el scanner no puede verificar', () {
      final container = _scannerContainer({2: List<int>.filled(10, 0)});

      expect(container.read(labelScannerProvider).canVerify, isFalse);
    });

    test('sin claves, el scanner no puede verificar', () {
      final container = _scannerContainer(const <int, List<int>>{});

      expect(container.read(labelScannerProvider).canVerify, isFalse);
    });

    test(
      'verifica de punta a punta con la clave del vector inyectada',
      () async {
        final vector = _vector();
        final container = _scannerContainer({
          vector['key_id'] as int: base64.decode(
            vector['public_key_base64'] as String,
          ),
        });

        final result = await container
            .read(labelScannerProvider)
            .scan(vector['qr_content'] as String);

        expect(result.isValid, isTrue);
      },
    );
  });
}
