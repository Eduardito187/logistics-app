import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/widgets/empty_state.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_deliver_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_pickup_screen.dart';

import '../carrier_test_harness.dart';
import '../../../support/button_finders.dart';

// Pantallas de escaneo del transportista (recoger/entregar). El escaneo real
// requiere cámara (scanAndVerifyLabel → scanCode), así que se cubre el estado
// inicial vacío y el botón de acción habilitado.
// FALENCIA DETECTADA: el flujo de escaneo-verificación (válido/ inválido, y el
// registro del CarrierScanRecord con su ScanOutcomePill) no es alcanzable en
// widget test porque abre la pantalla de cámara. Ver sección de falencias.

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: syncBadgeOverrides(),
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('recoger: estado vacío inicial y botón de escanear habilitado', (
    tester,
  ) async {
    await _pump(tester, const CarrierPickupScreen());

    expect(find.text('Escanear al recoger'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Sin bultos recogidos'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Escanear bulto'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'entregar: estado vacío inicial y botón de registrar habilitado',
    (tester) async {
      await _pump(tester, const CarrierDeliverScreen());

      expect(find.text('Escanear al entregar'), findsOneWidget);
      expect(find.text('Sin entregas registradas'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Registrar entrega'),
      );
      expect(button.onPressed, isNotNull);
    },
  );
}
