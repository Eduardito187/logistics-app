import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/widgets/utilization_card.dart';

import '../support/driver_test_support.dart';

// Indicadores de utilización: se muestran SOLO métricas útiles, en español y
// formateadas; nada de uuid ni fechas crudas.

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('muestra métricas formateadas (sin uuid ni campos crudos)', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        vehicleUtilizationProvider.overrideWith(
          (ref) async => <String, Object?>{
            'vehicle_id': '01a1-uuid-oculto',
            'from': '2026-10-06',
            'to': '2026-11-05',
            'departures_count': 5,
            'km_traveled': 441,
            'hours_on_road': 12,
            'last_odometer_km': 123280,
            'last_odometer_read_at': '2026-11-04T06:00:00-04:00',
          },
        ),
      ],
      child: const Scaffold(body: UtilizationCard()),
    );

    expect(find.text('Utilización (últimos 30 días)'), findsOneWidget);
    expect(find.text('Salidas'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Km recorridos'), findsOneWidget);
    expect(find.text('441 km'), findsOneWidget);
    expect(find.text('Horas en ruta'), findsOneWidget);
    expect(find.text('12 h'), findsOneWidget);
    expect(find.textContaining('Odómetro'), findsOneWidget);
    expect(find.text('123.280 km'), findsOneWidget);
    // No se muestra el uuid ni los nombres crudos de los campos.
    expect(find.textContaining('01a1-uuid-oculto'), findsNothing);
    expect(find.text('vehicle id'), findsNothing);
    expect(find.text('from'), findsNothing);
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
