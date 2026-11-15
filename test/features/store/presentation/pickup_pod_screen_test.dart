import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/button_finders.dart';
import '../pickup_pod_support.dart';
import '../store_fixtures.dart';

// Entrega de un recojo en tienda: datos del cliente, pasos (firma, foto,
// documento) y la lista de productos con lo que el personal necesita para
// ubicarlos (nombre, SKU, código de etiqueta). Los flujos de escaneo y registro
// están en pickup_pod_scan_test.dart.

final _shipment = shipment(
  customerName: 'Ana Pérez',
  customerDocumentId: '12345678',
  customerPhone: '70000000',
);

void main() {
  testWidgets('muestra los datos del cliente del pedido', (tester) async {
    await pumpPickupPod(tester, shipment: _shipment, units: const []);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Pedido DM-260012345'), findsOneWidget);
    expect(find.text('Documento: 12345678'), findsOneWidget);
    expect(find.text('Teléfono: 70000000'), findsOneWidget);
  });

  testWidgets('mismos pasos que el chofer: firma, foto y documento', (
    tester,
  ) async {
    await pumpPickupPod(tester, shipment: _shipment);

    expect(find.text('1 · Firma del cliente'), findsOneWidget);
    expect(find.text('2 · Foto de entrega (obligatoria)'), findsOneWidget);
    expect(find.text('3 · Documento del cliente (opcional)'), findsOneWidget);
    expect(find.text('4 · Productos del pedido'), findsOneWidget);
    // Ya no se pide digitar ni escanear un "QR del cliente".
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('QR del cliente'), findsNothing);
  });

  testWidgets('firmar muestra la vista previa y permite volver a firmar', (
    tester,
  ) async {
    await pumpPickupPod(tester, shipment: _shipment);

    await tapSign(tester);

    expect(find.text('Firmado por el cliente.'), findsOneWidget);
    expect(find.byKey(const ValueKey('signature-preview')), findsOneWidget);
    expect(find.text('Volver a firmar'), findsOneWidget);
  });

  testWidgets('cancelar la firma la deja pendiente', (tester) async {
    await pumpPickupPod(tester, shipment: _shipment, signs: false);

    await tapSign(tester);

    expect(find.text('Pedile al cliente que firme.'), findsOneWidget);
    expect(find.text('Firma del cliente'), findsOneWidget);
  });

  testWidgets('lista los productos con nombre, SKU y código de etiqueta', (
    tester,
  ) async {
    await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: [
        unit(
          unitId: '01JB8ZQ4X7K2M9N5P6R7S8T9VW',
          label: 'A1',
          sku: 'TV-55',
          productName: 'Televisor 55"',
        ),
        unit(unitId: 'unit-2'),
      ],
    );

    expect(find.text('Entregados 0 de 2 producto(s).'), findsOneWidget);
    expect(find.text('Televisor 55"'), findsOneWidget);
    // SKU + código de la etiqueta (abreviado) para ubicarlo en el almacén.
    expect(find.text('SKU TV-55 · Etiqueta …S8T9VW'), findsOneWidget);
    // Sin datos de producto, igual se ve el código de su etiqueta.
    expect(find.text('Etiqueta unit-2'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
  });

  testWidgets('sin productos muestra 0 de 0 y no ofrece registrar', (
    tester,
  ) async {
    await pumpPickupPod(tester, shipment: _shipment, units: const []);

    expect(find.text('Entregados 0 de 0 producto(s).'), findsOneWidget);
    expect(findButtonWithText<FilledButton>('Registrar entrega'), findsNothing);
  });

  testWidgets('pedido ya entregado: no se puede volver a entregar', (
    tester,
  ) async {
    await pumpPickupPod(
      tester,
      shipment: _shipment,
      onGetDeliveryState: (shipmentId) async => delivery(
        shipmentId: shipmentId,
        podUnitIds: const ['unit-1', 'unit-2'],
      ),
    );

    expect(find.text('Entregados 2 de 2 producto(s).'), findsOneWidget);
    expect(find.text('Pedido entregado'), findsOneWidget);
    expect(
      findButtonWithText<FilledButton>('Escanear productos'),
      findsNothing,
    );
  });

  testWidgets('sin red el contador arranca en 0 y la pantalla no falla', (
    tester,
  ) async {
    // Sin `onGetDeliveryState` el repositorio falso falla: el POD igual abre.
    await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: [unit(unitId: 'unit-1')],
    );

    expect(find.text('Entregados 0 de 1 producto(s).'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.textContaining('No se pudo'), findsNothing);
  });
}
