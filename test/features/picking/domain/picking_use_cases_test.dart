import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emit_label_line.dart';
import 'package:logistics_app/core/api/models/emit_labels_request.dart';
import 'package:logistics_app/core/api/models/preparation_scan_request.dart';
import 'package:logistics_app/core/api/models/reprint_labels_request.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/features/picking/domain/usecases/emit_labels.dart';
import 'package:logistics_app/features/picking/domain/usecases/get_order_labels.dart';
import 'package:logistics_app/features/picking/domain/usecases/get_signed_zpl.dart';
import 'package:logistics_app/features/picking/domain/usecases/record_preparation_scan.dart';
import 'package:logistics_app/features/picking/domain/usecases/reprint_labels.dart';

import '../picking_test_harness.dart';

// Casos de uso del feature (CQRS). Cada uno delega en el repositorio: se
// verifica que pasa los argumentos tal cual, devuelve el resultado y propaga el
// error (ApiException como Failure del dominio).

void main() {
  group('GetOrderLabels (Query)', () {
    test('devuelve las etiquetas del pedido pedido', () async {
      final repo = FakePickingRepository(
        onGetOrderLabels: (order) async {
          expect(order, 'EXT-9');
          return [buildLabel(labelId: 'L1'), buildLabel(labelId: 'L2')];
        },
      );

      final labels = await GetOrderLabels(repo).call('EXT-9');

      expect(labels.map((l) => l.labelId), ['L1', 'L2']);
    });

    test('propaga ApiException', () async {
      final repo = FakePickingRepository(
        onGetOrderLabels: (_) async =>
            throw const ApiException(status: 404, title: 'No existe'),
      );

      expect(
        () => GetOrderLabels(repo).call('EXT-9'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('EmitLabels (Command)', () {
    test('reenvía número de pedido y cuerpo al repositorio', () async {
      final repo = FakePickingRepository(
        onEmitLabels: (_, _) async => [buildLabel()],
      );
      final body = EmitLabelsRequest(
        origin: 'LPZ',
        destination: 'SCZ',
        lines: const [EmitLabelLine(sku: 'SKU1', name: 'Uno', quantity: 2)],
      );

      final emitted = await EmitLabels(repo).call('EXT-1', body);

      expect(emitted, hasLength(1));
      expect(repo.emitCalls, 1);
      expect(repo.lastEmitOrder, 'EXT-1');
      expect(repo.lastEmitBody, same(body));
    });

    test('propaga el 409 (ya hay etiquetas vigentes)', () async {
      final repo = FakePickingRepository(
        onEmitLabels: (_, _) async =>
            throw const ApiException(status: 409, title: 'Conflicto'),
      );

      await expectLater(
        EmitLabels(repo).call(
          'EXT-1',
          const EmitLabelsRequest(origin: 'a', destination: 'b', lines: []),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.isConflict, 'isConflict', isTrue),
        ),
      );
    });
  });

  group('ReprintLabels (Command)', () {
    test('reenvía número de pedido y cuerpo con motivo', () async {
      final repo = FakePickingRepository(
        onReprintLabels: (_, _) async => [buildLabel(revoked: false)],
      );
      final body = ReprintLabelsRequest(
        origin: 'LPZ',
        destination: 'SCZ',
        lines: const [EmitLabelLine(sku: 'SKU1', name: 'Uno', quantity: 1)],
        reason: 'etiqueta dañada',
      );

      await ReprintLabels(repo).call('EXT-2', body);

      expect(repo.reprintCalls, 1);
      expect(repo.lastReprintOrder, 'EXT-2');
      expect(repo.lastReprintBody?.reason, 'etiqueta dañada');
    });

    test('propaga ApiException', () async {
      final repo = FakePickingRepository(
        onReprintLabels: (_, _) async =>
            throw const ApiException(status: 422, title: 'Inválido'),
      );

      expect(
        () => ReprintLabels(repo).call(
          'EXT-2',
          const ReprintLabelsRequest(
            origin: 'a',
            destination: 'b',
            lines: [],
            reason: 'x',
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('GetSignedZpl (Query)', () {
    test('devuelve el ZPL firmado por el backend', () async {
      final repo = FakePickingRepository(
        onGetSignedZpl: (order) async => '^XA[$order]^XZ',
      );

      expect(await GetSignedZpl(repo).call('EXT-3'), '^XA[EXT-3]^XZ');
    });

    test(
      'propaga ApiException (para el respaldo offline del caller)',
      () async {
        final repo = FakePickingRepository(
          onGetSignedZpl: (_) async =>
              throw const ApiException(status: 0, title: 'Sin conexión'),
        );

        expect(
          () => GetSignedZpl(repo).call('EXT-3'),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });

  group('RecordPreparationScan (Command, offline-first)', () {
    PreparationScanRequest scan() => PreparationScanRequest(
      shipmentId: 'EXT-1',
      unitId: 'LBL-1',
      lat: 0,
      lng: 0,
      occurredAt: DateTime(2026, 3, 9, 10),
      vehicleId: 'V1',
    );

    test('devuelve sent cuando la cola lo envió en línea', () async {
      final repo = FakePickingRepository(
        onRecordScan: (_) async => SubmitOutcome.sent,
      );

      expect(
        await RecordPreparationScan(repo).call(scan()),
        SubmitOutcome.sent,
      );
      expect(repo.recordScanCalls, 1);
      expect(repo.lastScan?.unitId, 'LBL-1');
      expect(repo.lastScan?.vehicleId, 'V1');
    });

    test('devuelve queued cuando no hay señal (se encola)', () async {
      final repo = FakePickingRepository(
        onRecordScan: (_) async => SubmitOutcome.queued,
      );

      expect(
        await RecordPreparationScan(repo).call(scan()),
        SubmitOutcome.queued,
      );
    });

    test('devuelve failed ante un error de datos de la API', () async {
      final repo = FakePickingRepository(
        onRecordScan: (_) async => SubmitOutcome.failed,
      );

      expect(
        await RecordPreparationScan(repo).call(scan()),
        SubmitOutcome.failed,
      );
    });
  });
}
