import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/presentation/controllers/selected_store_node_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/widgets/store_selector.dart';

import '../../store_fixtures.dart';

// Selector del nodo destino: lista los nodos, guarda la elección por id y maneja
// el vacío y el error.

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Future<List<Node>> Function() load,
) async {
  final container = ProviderContainer(
    // Sin reintentos: el retry por defecto deja un Timer pendiente tras el
    // dispose del árbol en el caso de error.
    retry: (_, _) => null,
    overrides: [storeNodesProvider.overrideWith((ref) => load())],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: StoreSelector())),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('con nodos, elegir uno lo guarda en selectedStoreNodeProvider', (
    tester,
  ) async {
    final node = storeNode(name: 'Tienda Centro', code: 'ST-01');
    final container = await _pump(tester, () async => [node, originNode()]);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tienda Centro  ·  ST-01').last);
    await tester.pumpAndSettle();

    expect(container.read(selectedStoreNodeProvider)?.id, node.id);
  });

  testWidgets('sin nodos muestra el mensaje de red vacía', (tester) async {
    await _pump(tester, () async => <Node>[]);
    expect(find.text('No hay nodos activos en la red.'), findsOneWidget);
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      () async => throw const ApiException(status: 500, title: 'Error'),
    );
    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
