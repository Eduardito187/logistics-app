import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/node_reception_view.dart';
import 'package:logistics_app/core/api/models/node_reception_view_status.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/reception_detail_screen.dart';
import 'package:logistics_app/features/store/presentation/widgets/open_reception_panel.dart';

import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Detalle de recepción: abrir recepción (null), progreso (recibidos/faltan/
// sobrantes), pastilla "conciliada" y las dos escrituras con red (abrir y
// conciliar) en sus caminos ok y error.

final _node = storeNode();
final _shipment = shipment();
final _key = (shipmentId: _shipment.id, nodeId: _node.id);

Future<FakeStoreRepository> _pump(
  WidgetTester tester, {
  required NodeReceptionView? reception,
  List<UnitTracking>? units,
  List<Node>? nodes,
  FakeStoreRepository? repo,
}) async {
  final fakeRepo = repo ?? FakeStoreRepository();
  final overrides = <Override>[
    ...syncBadgeOverrides(),
    storeRepositoryProvider.overrideWithValue(fakeRepo),
    nodeReceptionProvider(_key).overrideWith((ref) async => reception),
    shipmentUnitsProvider(_shipment.id).overrideWith(
      (ref) async => units ?? [unit(unitId: 'unit-1'), unit(unitId: 'unit-2')],
    ),
    storeNodesProvider.overrideWith(
      (ref) async => nodes ?? [_node, originNode()],
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
  return fakeRepo;
}

void main() {
  testWidgets(
    'recepción null muestra el panel para abrir con el nodo de origen',
    (tester) async {
      await _pump(tester, reception: null);

      expect(find.byType(OpenReceptionPanel), findsOneWidget);
      expect(
        find.text(
          'Este envío tiene 2 bulto(s) esperado(s). '
          'Indica el nodo de origen para abrir la recepción.',
        ),
        findsOneWidget,
      );
      expect(find.text('Nodo de origen'), findsOneWidget);
    },
  );

  testWidgets('recepción abierta muestra el progreso recibidos/faltan', (
    tester,
  ) async {
    await _pump(
      tester,
      reception: reception(
        status: NodeReceptionViewStatus.open,
        expected: const ['unit-1', 'unit-2'],
        received: const ['unit-1'],
        missing: const ['unit-2'],
      ),
    );

    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Recibidos'), findsOneWidget);
    expect(find.text('Faltan'), findsOneWidget);
    // Acciones disponibles mientras la recepción está abierta.
    expect(find.widgetWithText(FilledButton, 'Escanear bulto'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Conciliar y cerrar'),
      findsOneWidget,
    );
  });

  testWidgets('recepción con sobrantes muestra la métrica de sobrantes', (
    tester,
  ) async {
    await _pump(
      tester,
      reception: reception(
        status: NodeReceptionViewStatus.open,
        expected: const ['unit-1', 'unit-2'],
        received: const ['unit-1'],
        missing: const ['unit-2'],
        surplus: const ['unit-9'],
      ),
    );

    expect(find.text('Sobrantes (no esperados)'), findsOneWidget);
  });

  testWidgets(
    'recepción conciliada muestra la pastilla y oculta las acciones',
    (tester) async {
      await _pump(
        tester,
        reception: reception(
          status: NodeReceptionViewStatus.reconciled,
          expected: const ['unit-1', 'unit-2'],
          received: const ['unit-1', 'unit-2'],
          missing: const [],
        ),
      );

      expect(find.text('Recepción conciliada'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Escanear bulto'), findsNothing);
      expect(
        find.widgetWithText(OutlinedButton, 'Conciliar y cerrar'),
        findsNothing,
      );
    },
  );

  testWidgets('abrir recepción ok: elige origen, llama al repo y avisa éxito', (
    tester,
  ) async {
    final repo = await _pump(tester, reception: null);

    // Elegir el nodo de origen en el dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CD Santa Cruz · CD-SCZ').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir recepción'));
    await tester.pumpAndSettle();

    expect(repo.openCalls, 1);
    expect(repo.lastOpenRequest?.shipmentId, _shipment.id);
    expect(repo.lastOpenRequest?.originNodeId, 'node-cd');
    expect(find.text('Recepción abierta.'), findsOneWidget);
  });

  testWidgets('abrir recepción con error de API muestra el mensaje de error', (
    tester,
  ) async {
    final repo = FakeStoreRepository(
      onOpenNodeReception: (_) async => throw const ApiException(
        status: 409,
        title: 'Conflicto',
        detail: 'La recepción ya existe.',
      ),
    );
    await _pump(tester, reception: null, repo: repo);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CD Santa Cruz · CD-SCZ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abrir recepción'));
    await tester.pumpAndSettle();

    expect(find.text('La recepción ya existe.'), findsOneWidget);
    expect(find.text('Recepción abierta.'), findsNothing);
  });

  testWidgets(
    'conciliar ok: confirma el diálogo, llama al repo y avisa cierre',
    (tester) async {
      final repo = await _pump(
        tester,
        reception: reception(status: NodeReceptionViewStatus.open),
      );

      final reconcileButton = find.widgetWithText(
        OutlinedButton,
        'Conciliar y cerrar',
      );
      await tester.ensureVisible(reconcileButton);
      await tester.pumpAndSettle();
      await tester.tap(reconcileButton);
      await tester.pumpAndSettle();
      expect(find.text('Conciliar recepción'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Conciliar'));
      await tester.pumpAndSettle();

      expect(repo.reconcileCalls, 1);
      expect(repo.lastReconcileRequest?.shipmentId, _shipment.id);
      expect(find.text('Recepción conciliada y cerrada.'), findsOneWidget);
    },
  );

  testWidgets('conciliar: cancelar el diálogo no llama al repo', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      reception: reception(status: NodeReceptionViewStatus.open),
    );

    final reconcileButton = find.widgetWithText(
      OutlinedButton,
      'Conciliar y cerrar',
    );
    await tester.ensureVisible(reconcileButton);
    await tester.pumpAndSettle();
    await tester.tap(reconcileButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.reconcileCalls, 0);
  });

  testWidgets('conciliar con error de API muestra el mensaje de error', (
    tester,
  ) async {
    final repo = FakeStoreRepository(
      // 422 (regla de negocio): la UI muestra el `detail` del backend. Un 5xx
      // mostraría el texto genérico de servidor (ver ApiException.message).
      onReconcileNodeReception: (_) async => throw const ApiException(
        status: 422,
        title: 'Error',
        detail: 'No se pudo conciliar.',
      ),
    );
    await _pump(
      tester,
      reception: reception(status: NodeReceptionViewStatus.open),
      repo: repo,
    );

    final reconcileButton = find.widgetWithText(
      OutlinedButton,
      'Conciliar y cerrar',
    );
    await tester.ensureVisible(reconcileButton);
    await tester.pumpAndSettle();
    await tester.tap(reconcileButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Conciliar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conciliar.'), findsOneWidget);
    expect(find.text('Recepción conciliada y cerrada.'), findsNothing);
  });
}
