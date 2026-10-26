import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/carrier_scan_record.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/signed_label_result.dart';

// Modelos de datos del transportista: registro de escaneo y etiqueta verificada.

void main() {
  test('CarrierScanRecord conserva los campos del escaneo', () {
    final at = DateTime(2026, 3, 1, 14, 30);
    const record = SignedLabelResult(
      unitId: 'unit-1',
      shipmentId: 'DM-1',
      sku: 'SKU-1',
    );
    final scan = CarrierScanRecord(
      unitId: record.unitId,
      title: record.sku,
      outcome: SubmitOutcome.queued,
      at: at,
    );

    expect(scan.unitId, 'unit-1');
    expect(scan.title, 'SKU-1');
    expect(scan.outcome, SubmitOutcome.queued);
    expect(scan.at, at);
  });

  test('SignedLabelResult mapea id/orderNumber/sku de la etiqueta', () {
    const result = SignedLabelResult(
      unitId: '01JB8ZQ4X7K2M9N5P6R7S8T9VW',
      shipmentId: 'DM-260012345',
      sku: 'LG-GT32WPP',
    );
    expect(result.unitId, '01JB8ZQ4X7K2M9N5P6R7S8T9VW');
    expect(result.shipmentId, 'DM-260012345');
    expect(result.sku, 'LG-GT32WPP');
  });

  test('addSessionRecord pone lo último arriba y acota la sesión', () {
    final records = <CarrierScanRecord>[];
    for (var i = 0; i <= kMaxSessionRecords + 5; i++) {
      addSessionRecord(
        records,
        CarrierScanRecord(
          unitId: 'unit-$i',
          title: 'SKU',
          outcome: SubmitOutcome.sent,
          at: DateTime(2026),
        ),
      );
    }
    expect(records, hasLength(kMaxSessionRecords));
    expect(records.first.unitId, 'unit-${kMaxSessionRecords + 5}');
    expect(records.last.unitId, 'unit-6');
  });
}
