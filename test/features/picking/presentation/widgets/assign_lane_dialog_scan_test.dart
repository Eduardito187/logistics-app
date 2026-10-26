import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/picking/presentation/widgets/assign_lane_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../support/fake_code_scanner.dart';

// Botón "Escanear" del diálogo de carril: el código leído llena el campo (no
// cierra el diálogo). La cámara se reemplaza con FakeCodeScanner.

/// Abre el diálogo y deja su resultado en `box[0]` al cerrarse.
Future<void> _open(
  WidgetTester tester,
  List<Object?> box,
  FakeCodeScanner scanner, {
  String? initial,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [codeScannerProvider.overrideWithValue(scanner.call)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                box[0] = await showDialog<String>(
                  context: context,
                  builder: (_) => AssignLaneDialog(initial: initial),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('"Escanear" llena el campo y "Guardar" devuelve el código', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    final scanner = FakeCodeScanner(['LANE-12']);
    await _open(tester, box, scanner);

    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();

    expect(scanner.requestedTitles, ['Escanear carril']);
    expect(scanner.requestedFormats.single, [
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
    ]);
    // El diálogo sigue abierto con el código cargado.
    expect(find.byType(AssignLaneDialog), findsOneWidget);
    expect(_fieldText(tester), 'LANE-12');
    expect(box[0], #pending);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(box[0], 'LANE-12');
  });

  testWidgets('el escaneo reemplaza el valor inicial', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box, FakeCodeScanner(['ABC-123']), initial: 'Viejo');
    expect(_fieldText(tester), 'Viejo');

    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();

    expect(_fieldText(tester), 'ABC-123');
  });

  testWidgets('cancelar el escaneo deja el campo como estaba', (tester) async {
    final box = <Object?>[#pending];
    final scanner = FakeCodeScanner([null]);
    await _open(tester, box, scanner, initial: 'Carril 1');

    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();

    expect(scanner.requestedTitles, ['Escanear carril']);
    expect(find.byType(AssignLaneDialog), findsOneWidget);
    expect(_fieldText(tester), 'Carril 1');
    expect(box[0], #pending);
  });

  testWidgets('un código escaneado con espacios se guarda recortado', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box, FakeCodeScanner(['  V-9  ']));

    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(box[0], 'V-9');
  });
}
