import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node_reception_view.dart';
import 'package:logistics_app/core/api/models/node_reception_view_status.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';
import 'package:logistics_app/features/store/domain/usecases/receive_unit_at_node.dart';
import 'package:logistics_app/features/store/presentation/controllers/locally_received_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/shelf_locations_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/reception_detail_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';
import '../../../support/button_finders.dart';

// Recepción de tienda: flujo escaneo -> recibir bulto. El escáner de cámara se
// reemplaza con `FakeCodeScanner` (vía `codeScannerProvider`) y el caso de uso
// `ReceiveUnitAtNode` con un fake que registra las llamadas (sin cola ni GPS).

final _node = storeNode();
final _shipment = shipment();
final _key = (shipmentId: _shipment.id, nodeId: _node.id);

const _signedUnitId = '01JB8ZQ4X7K2M9N5P6R7S8T9VW';

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

/// Scanner de etiquetas con la clave pública del vector registrada en [keyId].
LabelScanner _scannerWithKey(int keyId) {
  final key = base64.decode(_vector()['public_key_base64'] as String);
  return LabelScanner(LabelVerifier({keyId: key}));
}

/// Caso de uso falso: registra cada recepción y devuelve [outcome].
class _FakeReceiveUnitAtNode extends ReceiveUnitAtNode {
  _FakeReceiveUnitAtNode(super.ref, this.calls, this.outcome);

  final List<Map<String, String>> calls;
  final SubmitOutcome outcome;

  @override
  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String destinationNodeId,
    required String customerName,
  }) async {
    calls.add({
      'shipmentId': shipmentId,
      'unitId': unitId,
      'destinationNodeId': destinationNodeId,
      'customerName': customerName,
    });
    return outcome;
  }
}

class _Harness {
  final calls = <Map<String, String>>[];
  late FakeCodeScanner scanner;
  late ProviderContainer container;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required List<String?> codes,
  NodeReceptionView? view,
  LabelScanner? labelScanner,
  SubmitOutcome outcome = SubmitOutcome.sent,
}) async {
  // Superficie alta: el ListView es perezoso y en 800x600 deja botones fuera.
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness()..scanner = FakeCodeScanner(codes);
  final overrides = <Override>[
    ...syncBadgeOverrides(),
    storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
    nodeReceptionProvider(_key).overrideWith(
      (ref) async => view ?? reception(status: NodeReceptionViewStatus.open),
    ),
    storeNodesProvider.overrideWith((ref) async => [_node, originNode()]),
    codeScannerProvider.overrideWithValue(h.scanner.call),
    labelScannerProvider.overrideWithValue(labelScanner ?? LabelScanner(null)),
    receiveUnitAtNodeProvider.overrideWith(
      (ref) => _FakeReceiveUnitAtNode(ref, h.calls, outcome),
    ),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: ReceptionDetailScreen(args: (shipment: _shipment, node: _node)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  h.container = ProviderScope.containerOf(
    tester.element(find.byType(ReceptionDetailScreen)),
  );
  return h;
}

Future<void> _tapScan(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Escanear bulto'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'camino feliz: recibe el bulto escaneado, avisa y pide la ubicación',
    (tester) async {
      final h = await _pump(tester, codes: ['unit-2']);

      await _tapScan(tester);

      // Se pidió un escaneo de QR con el título de la pantalla.
      expect(h.scanner.requestedTitles, ['Escanear bulto']);
      expect(h.scanner.requestedFormats.single, [BarcodeFormat.qrCode]);
      // El caso de uso recibió el código escaneado y los datos del envío/nodo.
      expect(h.calls, [
        {
          'shipmentId': _shipment.id,
          'unitId': 'unit-2',
          'destinationNodeId': _node.id,
          'customerName': _shipment.customerName,
        },
      ]);
      expect(find.text('Registrado.'), findsOneWidget);
      // El conteo avanza con el estado local (unit-1 del server + unit-2).
      expect(find.text('2/2'), findsOneWidget);
      expect(h.container.read(locallyReceivedProvider)[_shipment.id], {
        'unit-2',
      });
      // Tras recibir, pide la ubicación en estante. No se cierra el diálogo
      // acá: cerrarlo dispara el bug del controller (ver tests de abajo).
      expect(find.text('Ubicación en estante'), findsOneWidget);
    },
  );

  // BUG: reception_detail_screen.dart:305 (_askShelfLocation) hace
  // `controller.dispose()` apenas `showDialog` devuelve, pero el diálogo sigue
  // montado durante la animación de salida y el TextField usa el controller
  // ya liberado ("A TextEditingController was used after being disposed").
  // Revienta tanto con "Guardar" como con "Omitir". (testWidgets solo acepta
  // skip bool, por eso el motivo va en este comentario.)
  testWidgets('guardar la ubicación en estante la registra para el bulto', (
    tester,
  ) async {
    final h = await _pump(tester, codes: ['unit-2']);

    await _tapScan(tester);
    await tester.enterText(find.byType(TextField), 'Pasillo 3 B2');
    await tester.tap(findButtonWithText<FilledButton>('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ubicación en estante'), findsNothing);
    expect(h.container.read(shelfLocationsProvider), {
      'unit-2': 'Pasillo 3 B2',
    });
  });

  testWidgets('omitir la ubicación en estante no guarda nada', (tester) async {
    final h = await _pump(tester, codes: ['unit-2']);

    await _tapScan(tester);
    await tester.tap(findButtonWithText<TextButton>('Omitir'));
    await tester.pumpAndSettle();

    expect(find.text('Ubicación en estante'), findsNothing);
    expect(h.calls, hasLength(1));
    expect(h.container.read(shelfLocationsProvider), isEmpty);
  });

  testWidgets('sin conexión: avisa que quedó en cola y el conteo avanza', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: ['unit-2'],
      outcome: SubmitOutcome.queued,
    );

    await _tapScan(tester);

    expect(h.calls.single['unitId'], 'unit-2');
    expect(find.text('Registrado.'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('cancelar el escáner no envía nada', (tester) async {
    final h = await _pump(tester, codes: [null]);

    await _tapScan(tester);

    expect(h.scanner.requestedTitles, hasLength(1));
    expect(h.calls, isEmpty);
    expect(find.text('Ubicación en estante'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets(
    'etiqueta firmada válida: recibe con el id del payload, no el QR crudo',
    (tester) async {
      final h = await _pump(
        tester,
        codes: [_vector()['qr_content'] as String],
        labelScanner: _scannerWithKey(1),
        view: reception(
          expected: const [_signedUnitId, 'unit-2'],
          received: const [],
          missing: const [_signedUnitId, 'unit-2'],
        ),
      );

      await _tapScan(tester);

      expect(h.calls.single['unitId'], _signedUnitId);
      expect(find.text('Registrado.'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    },
  );

  testWidgets('etiqueta con firma inválida: avisa en rojo y no recibe', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: [_vector()['tampered_qr_content'] as String],
      labelScanner: _scannerWithKey(1),
    );

    await _tapScan(tester);

    expect(h.calls, isEmpty);
    expect(
      find.text('Firma inválida: etiqueta editada o falsa.'),
      findsOneWidget,
    );
    expect(find.text('Ubicación en estante'), findsNothing);
    expect(h.container.read(locallyReceivedProvider), isEmpty);
  });

  testWidgets('etiqueta de clave desconocida: avisa y no recibe', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: [_vector()['qr_content'] as String],
      labelScanner: _scannerWithKey(99),
    );

    await _tapScan(tester);

    expect(h.calls, isEmpty);
    expect(
      find.text('Etiqueta de una clave desconocida: no se puede verificar.'),
      findsOneWidget,
    );
  });

  testWidgets('bulto no esperado: se recibe igual y aparece como sobrante', (
    tester,
  ) async {
    // Regla de recepción contra manifiesto: el sobrante se registra (no se
    // rechaza) para que la conciliación lo reporte.
    final h = await _pump(tester, codes: ['unit-9']);

    await _tapScan(tester);

    expect(h.calls.single['unitId'], 'unit-9');
    expect(find.text('Sobrantes (no esperados)'), findsOneWidget);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets(
    'bulto no esperado: el sobrante no infla "Recibidos" de los esperados',
    (tester) async {
      await _pump(tester, codes: ['unit-9']);

      await _tapScan(tester);

      // Esperados: unit-1 (recibido) y unit-2 (falta). El sobrante unit-9 se
      // muestra aparte, así que "Recibidos" debe quedar en 1/2, coherente con
      // "Faltan 1".
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('2/2'), findsNothing);
    },
  );

  testWidgets('el aviso del escaneo flota encima del botón fijo del pie', (
    tester,
  ) async {
    await _pump(tester, codes: ['unit-2']);

    await _tapScan(tester);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
  });
}
