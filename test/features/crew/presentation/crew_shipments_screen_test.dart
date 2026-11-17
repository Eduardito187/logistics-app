import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/crew/presentation/crew_shipments_screen.dart';

import '../../../support/screen_sizes.dart';
import '../../driver/support/driver_test_support.dart';

// Pantalla principal del TRIPULANTE: solo lectura de los envíos del camión al
// que lo asignaron. Reutiliza los providers de lectura del chofer (myCrew +
// ruta del día) y el soporte de tests del chofer.

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('muestra los envíos del camión asignado', (tester) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        crew: buildMyCrew(),
        route: buildRoute(
          totalStops: 2,
          completedStops: 0,
          stopsRemaining: 2,
          stops: [
            buildStop(
              id: 'a',
              sequence: 1,
              orderReference: 'PED-100',
              customerName: 'Cliente Uno',
              address: 'Av. Siempre Viva 123',
            ),
            buildStop(
              id: 'b',
              sequence: 2,
              orderReference: 'PED-200',
              customerName: 'Cliente Dos',
              status: DriverRouteStopStatus.completed,
            ),
          ],
        ),
      ),
      child: const CrewShipmentsScreen(),
    );

    expect(find.text('Mis envíos'), findsOneWidget);
    // Nada recortado: pedido, cliente y dirección completos.
    expect(find.text('PED-100'), findsOneWidget);
    expect(find.text('Cliente Uno'), findsOneWidget);
    expect(find.text('Av. Siempre Viva 123'), findsOneWidget);
    expect(find.text('PED-200'), findsOneWidget);
    // Estado por parada (solo lectura).
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Entregada'), findsOneWidget);
  });

  testWidgets('sin camión asignado (404) muestra un vacío amable', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        crewError: const ApiException(status: 404, title: 'sin asignación'),
      ),
      child: const CrewShipmentsScreen(),
    );

    expect(find.text('No estás asignado a un camión'), findsOneWidget);
    expect(find.text('Elegir otra fecha'), findsOneWidget);
  });

  testOnScreens('la lista de envíos no se desborda', (tester, screen) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        crew: buildMyCrew(),
        route: buildRoute(
          totalStops: 1,
          completedStops: 0,
          stopsRemaining: 1,
          stops: [
            buildStop(
              id: 'a',
              sequence: 1,
              orderReference: 'PED-100',
              customerName: 'Cliente Uno',
              address: 'Av. Siempre Viva 123, entre 2do y 3er anillo',
              destinationNodeName: 'Tienda Centro',
            ),
          ],
        ),
      ),
      child: withTextScale(const CrewShipmentsScreen()),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('PED-100'), findsOneWidget);
  });
}
