import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/scan_mode.dart';
import 'package:logistics_app/features/driver/presentation/scan_units_screen.dart';

import '../support/driver_test_support.dart';

// Escaneo repetido de bultos (carga/descarga).
//
// HUECO DE TESTABILIDAD: el flujo escaneo -> submit no es ejercitable en un test
// de widget porque `scanVerifiedUnit` abre el ScannerScreen de la cámara
// (mobile_scanner), sin un seam inyectable. Se cubren el estado inicial y las
// etiquetas por modo; el mapeo de SubmitOutcome a pastilla se cubre vía
// submit_feedback_test.dart.

void main() {
  testWidgets('modo carga: estado inicial y etiqueta del botón', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: const ScanUnitsScreen(
        mode: ScanMode.load,
        shipmentId: 'ship-1',
        title: 'Cargar envío',
      ),
    );

    expect(find.text('Cargar envío'), findsOneWidget);
    expect(find.text('Sin bultos'), findsOneWidget);
    expect(find.text('Escanea el primer bulto para empezar.'), findsOneWidget);
    expect(find.text('0 bulto(s) registrados'), findsOneWidget);
    expect(find.text('Escanear bulto para cargar'), findsOneWidget);
  });

  testWidgets('modo descarga: etiqueta del botón de descarga', (tester) async {
    await pumpScoped(
      tester,
      child: const ScanUnitsScreen(
        mode: ScanMode.unload,
        shipmentId: 'ship-1',
        nodeId: 'node-1',
        title: 'Descargar parada 1',
      ),
    );

    expect(find.text('Descargar parada 1'), findsOneWidget);
    expect(find.text('Escanear bulto para descargar'), findsOneWidget);
  });
}
