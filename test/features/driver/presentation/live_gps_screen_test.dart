import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/live_gps_screen.dart';
import 'package:logistics_app/features/driver/presentation/widgets/tracking_status_body.dart';

import '../support/driver_test_support.dart';

// Pantalla de rastreo GPS: solo informa (automático y obligatorio). El rastreo
// arranca solo; esta pantalla no tiene toggle de encender/apagar.

void main() {
  testWidgets('muestra la parada en curso como parada asociada', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        route: buildRoute(
          status: DriverRouteStatus.inProgress,
          currentStop: buildStop(
            shipmentId: 's1',
            customerName: 'Mercado Central',
            status: DriverRouteStopStatus.pending,
          ),
          stops: [
            buildStop(
              shipmentId: 's1',
              customerName: 'Mercado Central',
              status: DriverRouteStopStatus.pending,
            ),
          ],
        ),
      ),
      child: const LiveGpsScreen(),
    );

    expect(find.text('Rastreo del camión'), findsOneWidget);
    expect(find.byType(TrackingStatusBody), findsOneWidget);
    expect(find.text('Mercado Central'), findsWidgets);
    // No hay interruptor para encender/apagar el rastreo.
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('ruta sin paradas muestra el aviso de reanudación', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(route: buildEmptyRoute()),
      child: const LiveGpsScreen(),
    );

    expect(find.text('Ruta sin paradas pendientes'), findsOneWidget);
  });
}
