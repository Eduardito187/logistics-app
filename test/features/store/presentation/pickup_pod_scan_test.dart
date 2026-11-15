import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/button_finders.dart';
import '../pickup_pod_support.dart';
import '../store_fixtures.dart';

// Recojo en tienda, mismo proceso que la entrega del chofer: escanear los
// productos NO entrega nada; la entrega se registra recién con "Registrar
// entrega" (productos escaneados + firma del cliente + foto obligatoria).

final _shipment = shipment(customerName: 'Ana Pérez');

const _signedUnitId = '01JB8ZQ4X7K2M9N5P6R7S8T9VW';

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

/// Scanner de etiquetas con la clave pública del vector registrada en [keyId].
LabelScanner _scannerWithKey(int keyId) {
  final key = base64.decode(_vector()['public_key_base64'] as String);
  return LabelScanner(LabelVerifier({keyId: key}));
}

void main() {
  group('escanear productos (continuo, sin registrar)', () {
    testWidgets('escanear marca "Escaneado" y NO registra la entrega', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1'],
      );

      await tapScanProducts(tester);

      expect(h.products.requestedTitles, ['Escanear producto']);
      expect(h.products.requestedFormats.single, [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
      ]);
      expect(h.products.messages, ['Producto escaneado (1/2)']);
      // Honestidad de datos: escanear no es entregar.
      expect(h.pods, isEmpty);
      expect(find.text('Entregados 0 de 2 producto(s).'), findsOneWidget);
      expect(find.text('Escaneado'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      // Falta un producto: el botón sigue siendo escanear.
      expect(
        findButtonWithText<FilledButton>('Escanear productos'),
        findsOneWidget,
      );
      expect(
        findButtonWithText<FilledButton>('Registrar entrega'),
        findsNothing,
      );
    });

    testWidgets('producto ajeno al pedido: aviso rojo y no cuenta', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-de-otro-envio'],
      );

      await tapScanProducts(tester);

      expect(h.products.messages, ['No es de este pedido']);
      expect(find.text('Escaneado'), findsNothing);
    });

    testWidgets('el mismo producto dos veces no se duplica', (tester) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-1'],
      );

      await tapScanProducts(tester);

      expect(h.products.messages, [
        'Producto escaneado (1/2)',
        'Ese producto ya lo escaneaste',
      ]);
    });

    testWidgets('etiqueta firmada válida: se toma el id del payload', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: [_vector()['qr_content'] as String],
        labelScanner: _scannerWithKey(1),
        units: [unit(unitId: _signedUnitId, label: 'B1')],
      );

      await deliverAll(tester);

      expect(h.podUnitIds, [_signedUnitId]);
    });

    testWidgets('etiqueta con firma inválida: aviso rojo y no cuenta', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: [_vector()['tampered_qr_content'] as String],
        labelScanner: _scannerWithKey(1),
        units: [unit(unitId: _signedUnitId)],
      );

      await tapScanProducts(tester);

      expect(h.products.messages, ['Etiqueta inválida: editada o falsa']);
      expect(find.text('Escaneado'), findsNothing);
    });

    testWidgets('etiqueta de clave desconocida: avisa y no cuenta', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: [_vector()['qr_content'] as String],
        labelScanner: _scannerWithKey(99),
        units: [unit(unitId: _signedUnitId)],
      );

      await tapScanProducts(tester);

      expect(h.products.messages, ['Etiqueta inválida: clave desconocida']);
    });
  });

  group('registrar entrega', () {
    testWidgets('con todo escaneado pide firma y foto antes de registrar', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-2'],
      );

      await tapScanProducts(tester);

      final register = findButtonWithText<FilledButton>('Registrar entrega');
      expect(tester.widget<FilledButton>(register).onPressed, isNull);
      expect(
        find.text('Falta la firma del cliente y la foto de entrega.'),
        findsOneWidget,
      );

      await tapSign(tester);
      expect(tester.widget<FilledButton>(register).onPressed, isNull);
      expect(find.text('Falta la foto de entrega.'), findsOneWidget);

      await tapTakePhoto(tester);
      expect(tester.widget<FilledButton>(register).onPressed, isNotNull);
      expect(h.pods, isEmpty);
    });

    testWidgets('camino feliz: un POD por producto, con firma digital', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-2'],
        uploadedPath: 'evidence/pod/abc.jpg',
      );

      await deliverAll(tester);

      expect(h.pods, [
        for (final id in ['unit-1', 'unit-2'])
          {
            'shipmentId': _shipment.id,
            'unitId': id,
            'confirmation': 'FIRMA_DIGITAL',
            'customerName': 'Ana Pérez',
            'photoPath': 'evidence/pod/abc.jpg',
          },
      ]);
      // La firma viaja como evidencia ligada al cliente (con snapshot).
      expect(h.signatures.saved, hasLength(1));
      expect(h.enqueued, [
        {
          'shipmentId': _shipment.id,
          'filePath': '/tmp/firma.png',
          'kind': 'signature',
          'hasSnapshot': true,
        },
      ]);
      expect(find.text('Registrado.'), findsOneWidget);
      expect(find.text('Entregados 2 de 2 producto(s).'), findsOneWidget);
      expect(find.text('Entregado'), findsNWidgets(2));
      expect(find.text('Pedido entregado'), findsOneWidget);
    });

    testWidgets('documento opcional: viaja como evidencia del cliente', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-2'],
        photos: ['/tmp/pod.jpg', '/tmp/ci.jpg'],
        uploadedPath: 'evidence/pod/abc.jpg',
      );

      await tapScanProducts(tester);
      await tapSign(tester);
      await tapTakePhoto(tester);
      await tapTakeDocument(tester);
      await tapRegister(tester);

      expect(
        h.enqueued.map((e) => e['kind']),
        containsAll(<String>['id_document', 'signature']),
      );
      expect(
        h.enqueued.firstWhere((e) => e['kind'] == 'id_document'),
        containsPair('filePath', '/tmp/ci.jpg'),
      );
      expect(h.pods, hasLength(2));
    });

    testWidgets('sin conexión: queda registrado igual (offline invisible)', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-2'],
        outcome: SubmitOutcome.queued,
      );

      await deliverAll(tester);

      expect(h.pods, hasLength(2));
      expect(find.text('Registrado.'), findsOneWidget);
      expect(find.text('Entregados 2 de 2 producto(s).'), findsOneWidget);
    });

    testWidgets(
      'rechazo del backend: no queda entregado y se puede reintentar',
      (tester) async {
        final h = await pumpPickupPod(
          tester,
          shipment: _shipment,
          products: ['unit-1', 'unit-2'],
          // Solo el segundo producto es rechazado.
          outcomeFor: (unitId) =>
              unitId == 'unit-2' ? SubmitOutcome.failed : SubmitOutcome.sent,
        );

        await deliverAll(tester);

        expect(h.pods, hasLength(2));
        expect(
          find.text('No se pudo registrar. Intentá de nuevo.'),
          findsOneWidget,
        );
        // El que entró queda entregado; el rechazado sigue escaneado.
        expect(find.text('Entregados 1 de 2 producto(s).'), findsOneWidget);
        expect(find.text('Escaneado'), findsOneWidget);

        // Reintentar NO repite el producto que ya entró.
        await tapRegister(tester);
        expect(h.podUnitIds, ['unit-1', 'unit-2', 'unit-2']);
      },
    );
  });

  // Doble entrega entre reinicios: la lista en memoria se vacía cuando el
  // sistema operativo mata la app o el operario sale y vuelve a mitad del
  // retiro. Lo entregado se siembra con lo que el servidor ya confirmó.
  group('productos ya entregados según el servidor', () {
    testWidgets('al abrir se siembran y se ven como entregados', (
      tester,
    ) async {
      await pumpPickupPod(
        tester,
        shipment: _shipment,
        onGetDeliveryState: (shipmentId) async =>
            delivery(shipmentId: shipmentId, podUnitIds: const ['unit-1']),
      );

      expect(find.text('Entregados 1 de 2 producto(s).'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('no se puede entregar de nuevo tras un reinicio', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-2'],
        onGetDeliveryState: (_) async => delivery(podUnitIds: const ['unit-1']),
      );

      await deliverAll(tester);

      // Solo se registra el que faltaba: no se duplica el POD del entregado.
      expect(h.products.messages, [
        'Este producto ya fue entregado',
        'Producto escaneado (1/1)',
      ]);
      expect(h.podUnitIds, ['unit-2']);
    });

    testWidgets('los escaneos de carga no cuentan como entrega', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-2'],
        onGetDeliveryState: (_) async =>
            delivery(otherUnitIds: const ['unit-1']),
      );

      await deliverAll(tester);

      expect(h.podUnitIds, ['unit-1', 'unit-2']);
    });

    testWidgets('sin red el retiro sigue igual, sin error que trabe', (
      tester,
    ) async {
      final h = await pumpPickupPod(
        tester,
        shipment: _shipment,
        products: ['unit-1', 'unit-2'],
        onGetDeliveryState: (_) async =>
            throw const ApiException(status: 503, title: 'Caído'),
      );

      await deliverAll(tester);

      // Offline invisible: entrega normal y ningún aviso de error.
      expect(h.podUnitIds, ['unit-1', 'unit-2']);
      expect(find.text('Registrado.'), findsOneWidget);
      expect(find.textContaining('No se pudo'), findsNothing);
      expect(find.textContaining('Reintentar'), findsNothing);
    });
  });
}
