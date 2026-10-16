import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/driver/presentation/driver_common.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../support/driver_test_support.dart';

// scanVerifiedUnit (driver_common): escanea el QR del bulto vía el seam
// codeScannerProvider y verifica la firma Ed25519 offline con el vector
// compartido con el backend.

/// Botón que llama a scanVerifiedUnit y guarda cada resultado en [results].
class _Harness extends ConsumerWidget {
  const _Harness(this.results);

  final List<String?> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () async =>
            results.add(await scanVerifiedUnit(context, ref)),
        child: const Text('scan'),
      ),
    ),
  );
}

Future<List<String?>> _scanOnce(
  WidgetTester tester,
  FakeCodeScanner fake, {
  bool withKeys = true,
}) async {
  final results = <String?>[];
  await pumpScoped(
    tester,
    child: _Harness(results),
    overrides: [
      codeScannerProvider.overrideWithValue(fake.call),
      labelScannerProvider.overrideWithValue(
        vectorLabelScanner(withKeys: withKeys),
      ),
    ],
  );
  await tester.tap(find.text('scan'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('etiqueta con firma válida devuelve el unit_id', (tester) async {
    final fake = FakeCodeScanner([validLabelQr()]);
    final results = await _scanOnce(tester, fake);

    expect(results, [vectorUnitId]);
    expect(find.text('Etiqueta no válida'), findsNothing);
    // Pide un QR con el título y la ayuda por defecto del bulto.
    expect(fake.requestedTitles, ['Escanear bulto']);
    expect(fake.requestedFormats.single, [BarcodeFormat.qrCode]);
    expect(find.byType(ScannerScreen), findsNothing);
  });

  testWidgets('cancelar el escaneo devuelve null sin aviso', (tester) async {
    final results = await _scanOnce(tester, FakeCodeScanner([null]));

    expect(results, [null]);
    expect(find.text('Etiqueta no válida'), findsNothing);
  });

  testWidgets('firma alterada: null y aviso "Etiqueta no válida"', (
    tester,
  ) async {
    final results = await _scanOnce(
      tester,
      FakeCodeScanner([tamperedLabelQr()]),
    );

    expect(results, [null]);
    expect(find.text('Etiqueta no válida'), findsOneWidget);
  });

  testWidgets('QR que no es etiqueta (con claves): null y aviso', (
    tester,
  ) async {
    final results = await _scanOnce(tester, FakeCodeScanner(['no-es-json']));

    expect(results, [null]);
    expect(find.text('Etiqueta no válida'), findsOneWidget);
  });

  testWidgets('sin claves configuradas lee el id sin verificar la firma', (
    tester,
  ) async {
    final results = await _scanOnce(
      tester,
      FakeCodeScanner([tamperedLabelQr()]),
      withKeys: false,
    );

    // Sin claves no se puede verificar: el formato es válido y se acepta el id.
    expect(results, [vectorUnitId]);
    expect(find.text('Etiqueta no válida'), findsNothing);
  });

  testWidgets('sin claves y QR con formato inválido: null y aviso', (
    tester,
  ) async {
    final results = await _scanOnce(
      tester,
      FakeCodeScanner(['EAN-7791234567890']),
      withKeys: false,
    );

    expect(results, [null]);
    expect(find.text('Etiqueta no válida'), findsOneWidget);
  });
}
