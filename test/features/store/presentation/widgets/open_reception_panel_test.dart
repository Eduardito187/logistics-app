import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/widgets/open_reception_panel.dart';

import '../../store_fixtures.dart';
import '../../../../support/button_finders.dart';

// Panel para abrir una recepción: lista los bultos esperados, pide el nodo de
// origen (excluyendo el destino) y llama a onOpen con origen + ids esperados.

final _dest = storeNode();

Future<void> _pumpWithNodes(
  WidgetTester tester, {
  required Future<List<UnitTracking>> Function() units,
  required Future<List<Node>> Function() nodes,
  required Future<void> Function(Node origin, List<String> ids) onOpen,
  bool busy = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shipmentUnitsProvider(_dest.id).overrideWith((ref) => units()),
        storeNodesProvider.overrideWith((ref) => nodes()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OpenReceptionPanel(
            shipment: shipment(id: _dest.id),
            node: _dest,
            busy: busy,
            onOpen: onOpen,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el conteo de bultos esperados y el selector de origen', (
    tester,
  ) async {
    await _pumpWithNodes(
      tester,
      units: () async => [unit(unitId: 'u1'), unit(unitId: 'u2')],
      nodes: () async => [_dest, originNode()],
      onOpen: (_, _) async {},
    );

    expect(
      find.textContaining('Este envío tiene 2 bulto(s) esperado(s)'),
      findsOneWidget,
    );
    expect(find.text('Nodo de origen'), findsOneWidget);
  });

  testWidgets('el botón abrir está deshabilitado hasta elegir el origen', (
    tester,
  ) async {
    await _pumpWithNodes(
      tester,
      units: () async => [unit(unitId: 'u1')],
      nodes: () async => [_dest, originNode()],
      onOpen: (_, _) async {},
    );

    final before = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Abrir recepción'),
    );
    expect(before.onPressed, isNull);
  });

  testWidgets(
    'elegir origen y abrir llama a onOpen con origen + ids esperados',
    (tester) async {
      Node? gotOrigin;
      List<String>? gotIds;
      await _pumpWithNodes(
        tester,
        units: () async => [unit(unitId: 'u1'), unit(unitId: 'u2')],
        nodes: () async => [_dest, originNode()],
        onOpen: (origin, ids) async {
          gotOrigin = origin;
          gotIds = ids;
        },
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CD Santa Cruz · CD-SCZ').last);
      await tester.pumpAndSettle();
      await tester.tap(findButtonWithText<FilledButton>('Abrir recepción'));
      await tester.pumpAndSettle();

      expect(gotOrigin?.id, 'node-cd');
      expect(gotIds, ['u1', 'u2']);
    },
  );

  testWidgets('nodos con error muestra el aviso de carga de nodos', (
    tester,
  ) async {
    await _pumpWithNodes(
      tester,
      units: () async => [unit(unitId: 'u1')],
      nodes: () async => throw const ApiException(status: 500, title: 'Error'),
      onOpen: (_, _) async {},
    );

    expect(find.text('No se pudieron cargar los nodos.'), findsOneWidget);
  });
}
