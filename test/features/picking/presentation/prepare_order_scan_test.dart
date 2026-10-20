import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/picking/presentation/prepare_order_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';

// Botón "Escanear pedido": el código leído llena el campo y navega al pedido.
// La cámara se reemplaza con FakeCodeScanner vía codeScannerProvider.

Future<void> _pump(WidgetTester tester, FakeCodeScanner scanner) async {
  final router = GoRouter(
    initialLocation: '/picking/prepare',
    routes: [
      GoRoute(
        path: '/picking/prepare',
        builder: (_, _) => const PrepareOrderScreen(),
      ),
      GoRoute(
        path: '/picking/order/:orderNumber',
        builder: (_, state) => Scaffold(
          body: Text('ORDEN ${state.pathParameters['orderNumber']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [codeScannerProvider.overrideWithValue(scanner.call)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('escanear el pedido navega a su pantalla de armado', (
    tester,
  ) async {
    final scanner = FakeCodeScanner(['DIS-777']);
    await _pump(tester, scanner);

    await tester.tap(find.text('Escanear pedido'));
    await tester.pumpAndSettle();

    expect(scanner.requestedTitles, ['Escanear pedido']);
    expect(scanner.requestedFormats.single, [
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
    ]);
    expect(find.text('ORDEN DIS-777'), findsOneWidget);
  });

  testWidgets('el código escaneado se recorta antes de navegar', (
    tester,
  ) async {
    await _pump(tester, FakeCodeScanner(['  DIS-1  ']));

    await tester.tap(find.text('Escanear pedido'));
    await tester.pumpAndSettle();

    expect(find.text('ORDEN DIS-1'), findsOneWidget);
  });

  testWidgets('al volver, el campo conserva el código escaneado', (
    tester,
  ) async {
    await _pump(tester, FakeCodeScanner(['DIS-42']));

    await tester.tap(find.text('Escanear pedido'));
    await tester.pumpAndSettle();
    expect(find.text('ORDEN DIS-42'), findsOneWidget);

    final context = tester.element(find.text('ORDEN DIS-42'));
    GoRouter.of(context).pop();
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'DIS-42');
  });

  testWidgets('cancelar el escaneo no navega ni toca el campo', (tester) async {
    final scanner = FakeCodeScanner([null]);
    await _pump(tester, scanner);
    await tester.enterText(find.byType(TextField), 'PREVIO');

    await tester.tap(find.text('Escanear pedido'));
    await tester.pumpAndSettle();

    expect(scanner.requestedTitles, ['Escanear pedido']);
    expect(find.text('Preparar pedido'), findsOneWidget);
    expect(find.textContaining('ORDEN '), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'PREVIO');
  });

  testWidgets('un código en blanco no navega', (tester) async {
    await _pump(tester, FakeCodeScanner(['   ']));

    await tester.tap(find.text('Escanear pedido'));
    await tester.pumpAndSettle();

    expect(find.text('Preparar pedido'), findsOneWidget);
    expect(find.textContaining('ORDEN '), findsNothing);
  });
}
