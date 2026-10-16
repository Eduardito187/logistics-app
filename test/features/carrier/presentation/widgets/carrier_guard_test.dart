import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/carrier.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/carrier_guard.dart';

import '../../carrier_fixtures.dart';

// Guard del transportista: si hay uno elegido muestra el builder; si no, ofrece
// la lista de transportistas activos para elegir (con sus estados vacío/error).

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Carrier? selected,
  Future<List<Carrier>> Function()? carriers,
}) async {
  final container = ProviderContainer(
    // Sin reintentos: el retry por defecto deja un Timer pendiente tras el
    // dispose del árbol en el caso de error.
    retry: (_, _) => null,
    overrides: [
      if (carriers != null)
        carriersListProvider.overrideWith((ref) => carriers()),
    ],
  );
  addTearDown(container.dispose);
  if (selected != null) {
    container.read(selectedCarrierProvider.notifier).select(selected);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: CarrierGuard(
            builder: (context, carrier) => Text('Elegido: ${carrier.name}'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('con transportista elegido muestra el builder', (tester) async {
    await _pump(tester, selected: carrier(name: 'Transportes Andinos'));
    expect(find.text('Elegido: Transportes Andinos'), findsOneWidget);
  });

  testWidgets('sin elegido lista los transportistas y permite elegir', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      carriers: () async => [carrier(name: 'Transportes Andinos')],
    );

    expect(find.text('Elige tu transportista'), findsOneWidget);
    expect(find.text('Transportes Andinos'), findsOneWidget);
    expect(find.text('NIT 123456'), findsOneWidget);

    await tester.tap(find.text('Transportes Andinos'));
    await tester.pumpAndSettle();

    expect(
      container.read(selectedCarrierProvider)?.name,
      'Transportes Andinos',
    );
    expect(find.text('Elegido: Transportes Andinos'), findsOneWidget);
  });

  testWidgets('lista vacía no muestra tarjetas', (tester) async {
    await _pump(tester, carriers: () async => <Carrier>[]);
    expect(find.text('Elige tu transportista'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      carriers: () async => throw const ApiException(status: 500, title: 'x'),
    );
    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
