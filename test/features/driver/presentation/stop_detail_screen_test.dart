import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/stop_detail_screen.dart';

import '../support/driver_test_support.dart';

// Detalle de parada: datos del cliente, acciones de terreno y estado de entrega.

List<Object> _overrides(String shipmentId) => [
  deliveryStateProvider(shipmentId)
      .overrideWith((ref) async => buildDelivery(shipmentId: shipmentId)),
];

void main() {
  testWidgets('con coordenadas muestra datos, navegación y acciones', (
    tester,
  ) async {
    final stop = buildStop(
      sequence: 2,
      shipmentId: 'ship-9',
      customerName: 'Cliente X',
      orderReference: 'PED-9',
      address: 'Calle 1',
      etaAt: DateTime(2026, 10, 15, 14, 5),
      lat: -16.5,
      lng: -68.1,
      status: DriverRouteStopStatus.pending,
    );

    await pumpScoped(
      tester,
      overrides: _overrides('ship-9'),
      child: StopDetailScreen(stop: stop),
    );

    expect(find.text('Parada 2'), findsOneWidget); // appbar
    expect(find.text('Cliente X'), findsOneWidget);
    expect(find.text('PED-9'), findsOneWidget);
    expect(find.text('Calle 1'), findsOneWidget);
    expect(find.text('ETA 14:05'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Estado de la entrega'), findsOneWidget);

    // Acciones de terreno.
    expect(find.text('Navegar'), findsOneWidget);
    expect(find.text('Ver en el mapa'), findsOneWidget);
    expect(find.text('Descargar bultos'), findsOneWidget);
    expect(find.text('Entregado (prueba de entrega)'), findsOneWidget);
    expect(find.text('Entrega fallida'), findsOneWidget);
  });

  testWidgets('sin coordenadas no muestra navegación ni mapa', (tester) async {
    final stop = buildStop(shipmentId: 'ship-nc', customerName: 'Sin Geo');
    await pumpScoped(
      tester,
      overrides: _overrides('ship-nc'),
      child: StopDetailScreen(stop: stop),
    );

    expect(find.text('Navegar'), findsNothing);
    expect(find.text('Ver en el mapa'), findsNothing);
    // Las acciones que no dependen de coordenadas siguen presentes.
    expect(find.text('Descargar bultos'), findsOneWidget);
  });

  testWidgets('parada entregada muestra el estado "Entregada"', (tester) async {
    final stop = buildStop(
      shipmentId: 'ship-ok',
      status: DriverRouteStopStatus.completed,
    );
    await pumpScoped(
      tester,
      overrides: _overrides('ship-ok'),
      child: StopDetailScreen(stop: stop),
    );

    // Pastilla de estado de la parada (no confundir con la de la entrega).
    expect(find.text('Entregada'), findsWidgets);
  });
}
