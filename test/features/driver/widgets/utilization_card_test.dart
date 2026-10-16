import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/widgets/utilization_card.dart';

import '../support/driver_test_support.dart';

// Indicadores de utilización del vehículo (objeto libre del backend).

void main() {
  testWidgets('muestra las entradas con las claves humanizadas', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        vehicleUtilizationProvider.overrideWith(
          (ref) async => <String, Object?>{'active_days': 22, 'idle-days': 8},
        ),
      ],
      child: const Scaffold(body: UtilizationCard()),
    );

    expect(find.text('Utilización (últimos 30 días)'), findsOneWidget);
    // Las claves se humanizan reemplazando "_" y "-" por espacios.
    expect(find.text('active days'), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('idle days'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('sin datos muestra el aviso vacío', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        vehicleUtilizationProvider.overrideWith(
          (ref) async => <String, Object?>{},
        ),
      ],
      child: const Scaffold(body: UtilizationCard()),
    );
    expect(find.text('Sin datos de utilización disponibles.'), findsOneWidget);
  });
}
