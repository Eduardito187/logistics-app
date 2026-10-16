import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/features/driver/presentation/scan_mode.dart';
import 'package:logistics_app/features/driver/presentation/scanned_unit.dart';

// Tipos simples del escaneo de unidades.

void main() {
  test('ScanMode tiene carga y descarga', () {
    expect(ScanMode.values, containsAll([ScanMode.load, ScanMode.unload]));
    expect(ScanMode.values, hasLength(2));
  });

  test('ScannedUnit guarda el id del bulto y su desenlace', () {
    const unit = ScannedUnit('unit-9', SubmitOutcome.queued);
    expect(unit.unitId, 'unit-9');
    expect(unit.outcome, SubmitOutcome.queued);
  });
}
