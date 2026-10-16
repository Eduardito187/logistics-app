import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/vehicle_class.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/assignment_result.dart';

import '../../carrier_fixtures.dart';

// Resultado de asignación por volumen: vehículo sugerido, volumen y la tarifa
// más barata (o el aviso cuando no hay tarifa).

void main() {
  testWidgets('con tarifa muestra vehículo, volumen y tarifa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssignmentResult(
            assignment: assignment(
              vehicleClass: VehicleClass.trailer,
              tariffValue: tariff(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vehículo sugerido'), findsOneWidget);
    expect(find.text('Tráiler'), findsOneWidget);
    expect(find.text('12.5 m³'), findsOneWidget);
    expect(find.text('Tarifa más barata'), findsOneWidget);
    expect(find.textContaining('Bs'), findsOneWidget);
    expect(find.text('LPB → SCZ'), findsOneWidget);
  });

  testWidgets('sin tarifa muestra el aviso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssignmentResult(assignment: assignment())),
      ),
    );

    expect(
      find.text('No hay tarifa registrada para esta clase en el corredor.'),
      findsOneWidget,
    );
  });
}
