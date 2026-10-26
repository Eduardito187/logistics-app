import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../support/fake_code_scanner.dart';

// scanCode delega en codeScannerProvider cuando hay uno configurado: es el seam
// que permite probar los flujos escaneo -> submit sin cámara.

Future<void> _pumpButton(
  WidgetTester tester,
  List<String?> box, {
  List<Object> overrides = const [],
  bool withScope = true,
}) async {
  final app = MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            box.add(
              await scanCode(
                context,
                title: 'Escanear QR',
                formats: const [BarcodeFormat.qrCode],
              ),
            );
          },
          child: const Text('go'),
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    withScope ? ProviderScope(overrides: overrides.cast(), child: app) : app,
  );
}

void main() {
  testWidgets('con un escáner configurado devuelve su código sin cámara', (
    tester,
  ) async {
    final fake = FakeCodeScanner(['QR-1', null]);
    final box = <String?>[];
    await _pumpButton(
      tester,
      box,
      overrides: [codeScannerProvider.overrideWithValue(fake.call)],
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(box, ['QR-1', null]); // el null simula "cancelar"
    expect(fake.requestedTitles, ['Escanear QR', 'Escanear QR']);
    expect(fake.requestedFormats.first, [BarcodeFormat.qrCode]);
    expect(find.byType(ScannerScreen), findsNothing);
  });

  testWidgets('sin override abre la pantalla de cámara', (tester) async {
    final box = <String?>[];
    await _pumpButton(tester, box);

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScannerScreen), findsOneWidget);
  });

  testWidgets('sin ProviderScope no revienta y abre la cámara', (tester) async {
    final box = <String?>[];
    await _pumpButton(tester, box, withScope: false);

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScannerScreen), findsOneWidget);
  });
}
