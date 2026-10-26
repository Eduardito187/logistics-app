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
import 'package:logistics_app/core/location/gps_fix.dart';
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

import '../fake_continuous_scanner.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';
import '../../../support/button_finders.dart';

// Recepción de tienda: escaneo CONTINUO -> recibir cada producto. La cámara se
// reemplaza con `FakeContinuousScanner` (vía `continuousScannerProvider`, varios
// códigos por sesión) y el caso de uso `ReceiveUnitAtNode` con un fake que
// registra las llamadas (sin cola ni GPS). La ubicación en estante se pide UNA
// vez al terminar la ráfaga, para todo lo recibido en ella.

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
  final SubmitOutcome Function(String unitId) outcome;

  @override
  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String destinationNodeId,
    required String customerName,
    Future<GpsFix?>? location,
  }) async {
    calls.add({
      'shipmentId': shipmentId,
      'unitId': unitId,
      'destinationNodeId': destinationNodeId,
      'customerName': customerName,
    });
    return outcome(unitId);
  }
}

class _Harness {
  final calls = <Map<String, String>>[];

  /// Veces que se bajó la recepción del servidor.
  int receptionLoads = 0;
  late FakeContinuousScanner scanner;
  late ProviderContainer container;

  List<String> get unitIds => [for (final c in calls) c['unitId']!];
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<String> codes = const [],
  List<List<String>>? sessions,
  NodeReceptionView? view,
  LabelScanner? labelScanner,
  SubmitOutcome outcome = SubmitOutcome.sent,
  SubmitOutcome Function(String unitId)? outcomeFor,
}) async {
  // Superficie alta: la lista es perezosa y en 800x600 deja botones fuera.
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness()
    ..scanner = sessions != null
        ? FakeContinuousScanner.sessions(sessions)
        : FakeContinuousScanner(codes);
  final overrides = <Override>[
    ...syncBadgeOverrides(),
    storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
    nodeReceptionProvider(_key).overrideWith((ref) async {
      h.receptionLoads++;
      return view ?? reception(status: NodeReceptionViewStatus.open);
    }),
    storeNodesProvider.overrideWith((ref) async => [_node, originNode()]),
    continuousScannerProvider.overrideWithValue(h.scanner.call),
    labelScannerProvider.overrideWithValue(labelScanner ?? LabelScanner(null)),
    receiveUnitAtNodeProvider.overrideWith(
      (ref) =>
          _FakeReceiveUnitAtNode(ref, h.calls, outcomeFor ?? (_) => outcome),
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
  await tester.tap(findButtonWithText<FilledButton>('Escanear producto'));
  await tester.pumpAndSettle();
}

Future<void> _skipShelf(WidgetTester tester) async {
  await tester.tap(findButtonWithText<TextButton>('Omitir'));
  await tester.pumpAndSettle();
}

/// Recepción con 5 esperados y 1 ya recibido en el servidor.
NodeReceptionView _fiveExpected() => reception(
  expected: const ['unit-1', 'unit-2', 'unit-3', 'unit-4', 'unit-5'],
  received: const ['unit-1'],
  missing: const ['unit-2', 'unit-3', 'unit-4', 'unit-5'],
);

void main() {
  testWidgets(
    'camino feliz: recibe el producto, avisa sobre la cámara y pide estante',
    (tester) async {
      final h = await _pump(tester, codes: ['unit-2']);

      await _tapScan(tester);

      // Se abrió la cámara continua de QR con el título de la pantalla.
      expect(h.scanner.requestedTitles, ['Escanear producto']);
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
      expect(h.scanner.messages, ['Producto recibido (2/2)']);
      expect(h.scanner.okCount, 1);
      expect(find.text('1 producto recibido.'), findsOneWidget);
      // El conteo avanza con el estado local (unit-1 del server + unit-2).
      expect(find.text('2/2'), findsOneWidget);
      expect(h.container.read(locallyReceivedProvider)[_shipment.id], {
        'unit-2',
      });
      // Al terminar la ráfaga pide la ubicación en estante una sola vez.
      expect(find.text('Ubicación en estante'), findsOneWidget);
    },
  );

  testWidgets('varios productos en una sola sesión de cámara', (tester) async {
    final h = await _pump(
      tester,
      codes: ['unit-2', 'unit-3', 'unit-4'],
      view: _fiveExpected(),
    );

    await _tapScan(tester);

    // La cámara se abrió UNA vez para los tres.
    expect(h.scanner.requestedTitles, hasLength(1));
    expect(h.unitIds, ['unit-2', 'unit-3', 'unit-4']);
    expect(h.scanner.messages, [
      'Producto recibido (2/5)',
      'Producto recibido (3/5)',
      'Producto recibido (4/5)',
    ]);
    expect(find.text('3 productos recibidos.'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
    // Un único diálogo de estante, para los tres.
    expect(find.text('Ubicación en estante'), findsOneWidget);
    expect(find.text('Para los 3 productos recién recibidos.'), findsOneWidget);
  });

  testWidgets('la ubicación del final se guarda para toda la ráfaga', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: ['unit-2', 'unit-3'],
      view: _fiveExpected(),
    );

    await _tapScan(tester);
    await tester.enterText(find.byType(TextField), 'Pasillo 3 B2');
    await tester.tap(findButtonWithText<FilledButton>('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ubicación en estante'), findsNothing);
    expect(h.container.read(shelfLocationsProvider), {
      'unit-2': 'Pasillo 3 B2',
      'unit-3': 'Pasillo 3 B2',
    });
  });

  testWidgets('omitir la ubicación en estante no guarda nada', (tester) async {
    final h = await _pump(tester, codes: ['unit-2']);

    await _tapScan(tester);
    await _skipShelf(tester);

    expect(find.text('Ubicación en estante'), findsNothing);
    expect(h.calls, hasLength(1));
    expect(h.container.read(shelfLocationsProvider), isEmpty);
  });

  testWidgets('duplicado: el mismo producto otra vez avisa "Ya recibido"', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: ['unit-2', 'unit-2', 'unit-1'],
      view: _fiveExpected(),
    );

    await _tapScan(tester);

    // unit-2 se registra una sola vez; unit-1 ya estaba en el servidor.
    expect(h.unitIds, ['unit-2']);
    expect(h.scanner.messages, [
      'Producto recibido (2/5)',
      'Ya recibido',
      'Ya recibido',
    ]);
    expect(h.scanner.feedbacks.map((f) => f.ok), [true, false, false]);
  });

  testWidgets('sin conexión: queda en cola, aviso verde y el conteo avanza', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: ['unit-2'],
      outcome: SubmitOutcome.queued,
    );

    await _tapScan(tester);

    expect(h.calls.single['unitId'], 'unit-2');
    // Offline invisible: igual que enviado.
    expect(h.scanner.messages, ['Producto recibido (2/2)']);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('terminar sin leer nada no envía ni pide estante', (
    tester,
  ) async {
    final h = await _pump(tester);

    await _tapScan(tester);

    expect(h.scanner.requestedTitles, hasLength(1));
    expect(h.calls, isEmpty);
    expect(find.text('Ubicación en estante'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('1/2'), findsOneWidget);
    // El botón vuelve a quedar habilitado.
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Escanear producto'),
    );
    expect(button.onPressed, isNotNull);
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
      expect(h.scanner.messages, ['Producto recibido (1/2)']);
      expect(find.text('1/2'), findsOneWidget);
    },
  );

  testWidgets('etiqueta con firma inválida: aviso rojo y no recibe', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: [_vector()['tampered_qr_content'] as String],
      labelScanner: _scannerWithKey(1),
    );

    await _tapScan(tester);

    expect(h.calls, isEmpty);
    expect(h.scanner.messages, ['Etiqueta inválida: editada o falsa']);
    expect(h.scanner.okCount, 0);
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
    expect(h.scanner.messages, ['Etiqueta inválida: clave desconocida']);
  });

  testWidgets(
    'producto ajeno: aviso rojo "No es de este pedido" y queda como sobrante',
    (tester) async {
      // Regla de recepción contra manifiesto: el sobrante se registra (no se
      // rechaza) para que la conciliación lo reporte, pero se avisa en rojo.
      final h = await _pump(tester, codes: ['unit-9']);

      await _tapScan(tester);

      expect(h.calls.single['unitId'], 'unit-9');
      expect(h.scanner.messages, ['No es de este pedido']);
      expect(h.scanner.okCount, 0);
      expect(find.text('Sobrantes (no esperados)'), findsOneWidget);
      // El sobrante no infla "Recibidos" de los esperados.
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('2/2'), findsNothing);
    },
  );

  testWidgets('mezcla en una sesión: válido, ajeno, inválido y duplicado', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      codes: [
        'unit-2',
        'unit-9',
        _vector()['tampered_qr_content'] as String,
        'unit-2',
        'unit-3',
      ],
      labelScanner: _scannerWithKey(1),
      view: _fiveExpected(),
    );

    await _tapScan(tester);

    expect(h.unitIds, ['unit-2', 'unit-9', 'unit-3']);
    expect(h.scanner.messages, [
      'Producto recibido (2/5)',
      'No es de este pedido',
      'Etiqueta inválida: editada o falsa',
      'Ya recibido',
      'Producto recibido (3/5)',
    ]);
    // Registrados: 2 esperados + el sobrante.
    expect(find.text('3 productos recibidos.'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('el resumen flota encima del botón fijo del pie', (tester) async {
    await _pump(tester, codes: ['unit-2']);

    await _tapScan(tester);
    await _skipShelf(tester);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
  });

  group('refresco de la recepción con debounce', () {
    testWidgets('una ráfaga de escaneos hace un único GET al terminar', (
      tester,
    ) async {
      final h = await _pump(tester, codes: ['unit-2', 'unit-9']);
      expect(h.receptionLoads, 1);

      await _tapScan(tester);
      await _skipShelf(tester);

      // Durante la ráfaga no se re-baja la recepción: el conteo va local.
      expect(h.calls, hasLength(2));
      expect(h.receptionLoads, 1);
      expect(find.text('2/2'), findsOneWidget);

      await tester.pump(kReceptionRefreshDebounce);
      await tester.pump();
      expect(h.receptionLoads, 2);

      // Pasado el refresco no queda otro programado.
      await tester.pump(kReceptionRefreshDebounce * 2);
      expect(h.receptionLoads, 2);
    });

    testWidgets('dos sesiones seguidas acumulan el conteo local', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        sessions: [
          ['unit-2'],
          ['unit-3', 'unit-2'],
        ],
        view: _fiveExpected(),
      );

      await _tapScan(tester);
      await _skipShelf(tester);
      await _tapScan(tester);
      await _skipShelf(tester);

      expect(h.scanner.requestedTitles, hasLength(2));
      expect(h.unitIds, ['unit-2', 'unit-3']);
      expect(h.scanner.messages, [
        'Producto recibido (2/5)',
        'Producto recibido (3/5)',
        'Ya recibido',
      ]);
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('lo encolado (sin red) no dispara lecturas', (tester) async {
      final h = await _pump(
        tester,
        codes: ['unit-2'],
        outcome: SubmitOutcome.queued,
      );

      await _tapScan(tester);
      await _skipShelf(tester);
      await tester.pump(kReceptionRefreshDebounce * 2);

      expect(h.receptionLoads, 1);
    });

    testWidgets(
      'rechazado por el backend: aviso rojo, no cuenta ni pide estante',
      (tester) async {
        final h = await _pump(
          tester,
          codes: ['unit-2'],
          outcome: SubmitOutcome.failed,
        );

        await _tapScan(tester);

        expect(h.calls, hasLength(1));
        expect(h.scanner.messages, ['No se pudo registrar. Intentá de nuevo.']);
        expect(h.scanner.okCount, 0);
        expect(find.text('1/2'), findsOneWidget);
        expect(find.text('Ubicación en estante'), findsNothing);
        expect(
          h.container.read(locallyReceivedProvider)[_shipment.id],
          isEmpty,
        );
      },
    );

    testWidgets('un rechazo en la ráfaga no corta el resto y se reintenta', (
      tester,
    ) async {
      // El backend rechaza solo el PRIMER intento de unit-2.
      var unit2Tries = 0;
      final h = await _pump(
        tester,
        codes: ['unit-2', 'unit-3', 'unit-2'],
        view: _fiveExpected(),
        outcomeFor: (id) => id == 'unit-2' && unit2Tries++ == 0
            ? SubmitOutcome.failed
            : SubmitOutcome.sent,
      );

      await _tapScan(tester);

      expect(h.unitIds, ['unit-2', 'unit-3', 'unit-2']);
      expect(h.scanner.messages, [
        'No se pudo registrar. Intentá de nuevo.',
        'Producto recibido (2/5)',
        'Producto recibido (3/5)',
      ]);
      expect(find.text('2 productos recibidos.'), findsOneWidget);
    });
  });
}
