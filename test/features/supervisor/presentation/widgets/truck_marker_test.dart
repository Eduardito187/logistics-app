import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/theme/app_colors.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/truck_marker.dart';

import '../../support/supervisor_fixtures.dart';

// TruckMarker: ícono de camión; verde si se mueve, ámbar si está detenido.
// Reporta el toque al callback.

BoxDecoration _markerDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(TruckMarker),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('en movimiento usa el color de éxito (verde)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TruckMarker(vehicle: vehicleLive(moving: true), onTap: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    expect(_markerDecoration(tester).color, AppColors.success);
  });

  testWidgets('detenido usa el color de advertencia (ámbar)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TruckMarker(vehicle: vehicleLive(moving: false), onTap: () {}),
        ),
      ),
    );

    expect(_markerDecoration(tester).color, AppColors.warning);
  });

  testWidgets('al tocarlo dispara el callback onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TruckMarker(vehicle: vehicleLive(), onTap: () => tapped++),
        ),
      ),
    );

    await tester.tap(find.byType(TruckMarker));
    expect(tapped, 1);
  });
}
