import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/gps_fix.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/features/driver/presentation/widgets/tracking_status_body.dart';

import '../support/driver_test_support.dart';

// Cuerpo de la pantalla de rastreo: informa estado automático, contadores y
// última posición. No enciende ni apaga nada.

void main() {
  testWidgets(
    'rastreando muestra estado activo, posiciones y última posición',
    (tester) async {
      await pumpScoped(
        tester,
        overrides: [
          truckTrackingProvider.overrideWith(
            () => FakeTruckTracking(
              const TruckTrackingState(
                active: true,
                sent: 42,
                lastFix: GpsFix(lat: -16.5, lng: -68.15),
              ),
            ),
          ),
        ],
        child: Scaffold(
          body: TrackingStatusBody(target: buildStop(customerName: 'Mercado')),
        ),
      );

      expect(find.text('Rastreando'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Posiciones enviadas'), findsOneWidget);
      expect(find.text('-16.5000, -68.1500'), findsOneWidget);
      // Parada asociada.
      expect(find.text('Mercado'), findsOneWidget);
    },
  );

  testWidgets('en espera muestra el estado pasivo y "—" sin fix', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        truckTrackingProvider.overrideWith(
          () => FakeTruckTracking(const TruckTrackingState()),
        ),
      ],
      child: const Scaffold(body: TrackingStatusBody(target: null)),
    );

    expect(find.text('En espera de parada activa'), findsOneWidget);
    expect(find.text('En espera'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    // Sin parada: estado vacío explicativo.
    expect(find.text('Ruta sin paradas pendientes'), findsOneWidget);
  });
}
