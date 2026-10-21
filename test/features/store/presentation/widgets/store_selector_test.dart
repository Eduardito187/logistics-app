import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/features/store/presentation/controllers/selected_store_node_notifier.dart';
import 'package:logistics_app/features/store/presentation/widgets/store_selector.dart';

import '../../store_fixtures.dart';

// "Tu tienda": muestra la tienda asignada al usuario, sin poder cambiarla. El
// rol tienda solo opera sobre su nodo (el backend lo exige con 403).

Future<void> _pump(WidgetTester tester, Node? node) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [selectedStoreNodeProvider.overrideWithValue(node)],
      child: const MaterialApp(home: Scaffold(body: StoreSelector())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la tienda asignada, no editable', (tester) async {
    await _pump(tester, storeNode(name: 'Tienda Centro', code: 'ST-01'));

    expect(find.text('Tu tienda'), findsOneWidget);
    expect(find.text('Tienda Centro'), findsOneWidget);
    expect(find.text('ST-01'), findsOneWidget);
    // Sin desplegable: no se puede elegir otra tienda.
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('sin tienda asignada pide contactar al supervisor', (
    tester,
  ) async {
    await _pump(tester, null);

    expect(find.text('Sin tienda asignada'), findsOneWidget);
    expect(find.textContaining('Contactá a tu supervisor'), findsOneWidget);
  });
}
