import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/theme/app_colors.dart';
import 'package:logistics_app/features/driver/presentation/widgets/stop_pin.dart';

import '../support/driver_test_support.dart';

// Marcador numerado de una parada en el mapa, coloreado por estado.

void main() {
  testWidgets('muestra el número de secuencia', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(body: StopPin(stop: buildStop(sequence: 7))),
    );
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('el color del marcador refleja el estado', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: StopPin(stop: buildStop(status: DriverRouteStopStatus.failed)),
      ),
    );

    // StopPin dibuja un pin "gota" (TeardropPin) coloreado por estado.
    final pin = tester.widget<TeardropPin>(find.byType(TeardropPin));
    expect(pin.color, AppColors.danger);
  });
}
