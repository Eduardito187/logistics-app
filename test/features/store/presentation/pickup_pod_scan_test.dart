import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/location/gps_fix.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/store/domain/usecases/record_pod.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../fake_continuous_scanner.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';
import '../../../support/button_finders.dart';

// Entrega en mostrador: flujos escaneo -> submit. El QR del cliente usa el
// escáner de un código (`FakeCodeScanner` vía `codeScannerProvider`); los
// productos, el escaneo CONTINUO (`FakeContinuousScanner` vía
// `continuousScannerProvider`, varios por sesión). El caso de uso `RecordPod`
// es un fake que registra las llamadas (sin cola ni GPS).

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

/// Caso de uso falso: registra cada POD y devuelve [outcome].
class _FakeRecordPod extends RecordPod {
  _FakeRecordPod(super.ref, this.calls, this.outcome);

  final List<Map<String, String?>> calls;
  final SubmitOutcome outcome;

  @override
  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String confirmation,
    required String customerName,
    String? photoPath,
    Future<GpsFix?>? location,
  }) async {
    calls.add({
      'shipmentId': shipmentId,
      'unitId': unitId,
      'confirmation': confirmation,
      'customerName': customerName,
      'photoPath': photoPath,
    });
    return outcome;
  }
}

class _Harness {
  final calls = <Map<String, String?>>[];
  late FakeCodeScanner scanner;
  late FakeContinuousScanner products;

  List<String?> get unitIds => [for (final c in calls) c['unitId']];
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<String?> codes = const [],
  List<String> products = const [],
  List<List<String>>? productSessions,
  List<UnitTracking>? units,
  LabelScanner? labelScanner,
  SubmitOutcome outcome = SubmitOutcome.sent,
}) async {
  // Superficie alta: la lista es perezosa y en 800x600 deja botones fuera.
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness()
    ..scanner = FakeCodeScanner(codes)
    ..products = productSessions != null
        ? FakeContinuousScanner.sessions(productSessions)
        : FakeContinuousScanner(products);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        shipmentUnitsProvider(_shipment.id).overrideWith(
          (ref) async =>
              units ?? [unit(unitId: 'unit-1'), unit(unitId: 'unit-2')],
        ),
        codeScannerProvider.overrideWithValue(h.scanner.call),
        continuousScannerProvider.overrideWithValue(h.products.call),
        labelScannerProvider.overrideWithValue(
          labelScanner ?? LabelScanner(null),
        ),
        recordPodProvider.overrideWith(
          (ref) => _FakeRecordPod(ref, h.calls, outcome),
        ),
      ],
      child: MaterialApp(home: PickupPodScreen(shipment: _shipment)),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

final _confirmationField = find.widgetWithText(
  TextField,
  'QR del cliente o documento',
);

Future<void> _typeConfirmation(WidgetTester tester, String text) async {
  await tester.enterText(_confirmationField, text);
  await tester.pumpAndSettle();
}

Future<void> _tapDeliver(WidgetTester tester) async {
  await tester.tap(
    findButtonWithText<FilledButton>('Escanear y entregar producto'),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('QR del cliente (confirmación)', () {
    testWidgets('escanear llena la confirmación y habilita la entrega', (
      tester,
    ) async {
      final h = await _pump(tester, codes: ['CI-12345678']);

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();

      expect(h.scanner.requestedTitles, ['QR del cliente']);
      expect(
        tester.widget<TextField>(_confirmationField).controller!.text,
        'CI-12345678',
      );
      expect(
        find.text('Primero captura la confirmación del cliente.'),
        findsNothing,
      );
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Escanear y entregar producto'),
      );
      expect(button.onPressed, isNotNull);
      // Escanear la confirmación no registra ninguna entrega.
      expect(h.calls, isEmpty);
    });

    testWidgets('cancelar deja la confirmación vacía y la entrega bloqueada', (
      tester,
    ) async {
      final h = await _pump(tester, codes: [null]);

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();

      expect(h.scanner.requestedTitles, hasLength(1));
      expect(tester.widget<TextField>(_confirmationField).controller!.text, '');
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Escanear y entregar producto'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('cancelar no pisa una confirmación ya escrita', (tester) async {
      await _pump(tester, codes: [null]);
      await _typeConfirmation(tester, 'CI-999');

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(_confirmationField).controller!.text,
        'CI-999',
      );
    });
  });

  group('escanear y entregar productos (continuo)', () {
    testWidgets(
      'camino feliz: registra el POD del producto y lo marca entregado',
      (tester) async {
        final h = await _pump(tester, products: ['unit-1']);
        await _typeConfirmation(tester, '  CI-12345678  ');

        await _tapDeliver(tester);

        expect(h.products.requestedTitles, ['Escanear producto']);
        expect(h.products.requestedFormats.single, [BarcodeFormat.qrCode]);
        expect(h.calls, [
          {
            'shipmentId': _shipment.id,
            'unitId': 'unit-1',
            // La confirmación se envía recortada.
            'confirmation': 'CI-12345678',
            'customerName': 'Ana Pérez',
            'photoPath': null,
          },
        ]);
        expect(h.products.messages, ['Producto entregado (1/2)']);
        expect(find.text('1 producto entregado.'), findsOneWidget);
        expect(find.text('Entregados 1 de 2 producto(s).'), findsOneWidget);
        expect(find.text('Entregado'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);
      },
    );

    testWidgets('varios productos en una sola sesión de cámara', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        products: ['unit-1', 'unit-2', 'unit-3'],
        units: [
          unit(unitId: 'unit-1'),
          unit(unitId: 'unit-2'),
          unit(unitId: 'unit-3'),
        ],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.products.requestedTitles, hasLength(1));
      expect(h.unitIds, ['unit-1', 'unit-2', 'unit-3']);
      expect(h.products.messages, [
        'Producto entregado (1/3)',
        'Producto entregado (2/3)',
        'Producto entregado (3/3)',
      ]);
      expect(find.text('3 productos entregados.'), findsOneWidget);
      expect(find.text('Entregados 3 de 3 producto(s).'), findsOneWidget);
    });

    testWidgets('confirmación escaneada viaja en el POD', (tester) async {
      final h = await _pump(
        tester,
        codes: ['QR-CLIENTE-7'],
        products: ['unit-2'],
      );

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();
      await _tapDeliver(tester);

      expect(h.scanner.requestedTitles, ['QR del cliente']);
      expect(h.products.requestedTitles, ['Escanear producto']);
      expect(h.calls.single['unitId'], 'unit-2');
      expect(h.calls.single['confirmation'], 'QR-CLIENTE-7');
    });

    testWidgets('sin conexión: queda en cola y lo marca entregado', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        products: ['unit-1'],
        outcome: SubmitOutcome.queued,
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls, hasLength(1));
      // Offline invisible: igual que enviado.
      expect(h.products.messages, ['Producto entregado (1/2)']);
      expect(find.text('Entregados 1 de 2 producto(s).'), findsOneWidget);
    });

    testWidgets('rechazo del backend: aviso rojo y no queda entregado', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        products: ['unit-1'],
        outcome: SubmitOutcome.failed,
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls, hasLength(1));
      expect(h.products.messages, ['No se pudo registrar. Intentá de nuevo.']);
      expect(h.products.okCount, 0);
      expect(find.text('Entregados 0 de 2 producto(s).'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('terminar sin leer nada no registra', (tester) async {
      final h = await _pump(tester);
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.products.requestedTitles, hasLength(1));
      expect(h.calls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Entregados 0 de 2 producto(s).'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Escanear y entregar producto'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('etiqueta firmada válida: entrega con el id del payload', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        products: [_vector()['qr_content'] as String],
        labelScanner: _scannerWithKey(1),
        units: [unit(unitId: _signedUnitId, label: 'B1')],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls.single['unitId'], _signedUnitId);
      expect(find.text('Entregados 1 de 1 producto(s).'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
    });

    testWidgets('etiqueta con firma inválida: aviso rojo y no entrega', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        products: [_vector()['tampered_qr_content'] as String],
        labelScanner: _scannerWithKey(1),
        units: [unit(unitId: _signedUnitId)],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls, isEmpty);
      expect(h.products.messages, ['Etiqueta inválida: editada o falsa']);
      expect(find.text('Entregados 0 de 1 producto(s).'), findsOneWidget);
    });

    testWidgets('etiqueta de clave desconocida: avisa y no entrega', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        products: [_vector()['qr_content'] as String],
        labelScanner: _scannerWithKey(99),
        units: [unit(unitId: _signedUnitId)],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls, isEmpty);
      expect(h.products.messages, ['Etiqueta inválida: clave desconocida']);
    });

    testWidgets(
      'producto ajeno al pedido: no registra el POD ni cuenta como entregado',
      (tester) async {
        final h = await _pump(tester, products: ['unit-de-otro-envio']);
        await _typeConfirmation(tester, 'CI-1');

        await _tapDeliver(tester);

        // Entregar al cliente un bulto que no es de su pedido debe frenarse.
        expect(h.calls, isEmpty);
        expect(h.products.messages, ['No es de este pedido']);
        expect(find.text('Entregados 0 de 2 producto(s).'), findsOneWidget);
      },
    );

    testWidgets('producto ya entregado: no registra un segundo POD', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        productSessions: [
          ['unit-1', 'unit-1'],
          ['unit-1'],
        ],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);
      await _tapDeliver(tester);

      expect(h.calls, hasLength(1));
      expect(h.products.messages, [
        'Producto entregado (1/2)',
        'Ya entregado',
        'Ya entregado',
      ]);
      expect(find.text('Entregados 1 de 2 producto(s).'), findsOneWidget);
    });
  });
}
