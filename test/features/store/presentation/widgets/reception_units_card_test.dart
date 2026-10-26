import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/store/presentation/controllers/shelf_locations_notifier.dart';
import 'package:logistics_app/features/store/presentation/widgets/reception_units_card.dart';

// Lista de bultos del manifiesto: cada bulto con su estado (Recibido/Pendiente/
// Sobrante) y la ubicación en estante cuando se capturó.

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required List<String> expected,
  required Set<String> received,
  required Set<String> surplus,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          // Es un sliver: va dentro de un CustomScrollView.
          body: CustomScrollView(
            slivers: [
              ReceptionUnitsCard(
                expected: expected,
                received: received,
                surplus: surplus,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('marca recibidos, pendientes y sobrantes con su pastilla', (
    tester,
  ) async {
    await _pump(
      tester,
      expected: const ['unit-1', 'unit-2'],
      received: const {'unit-1'},
      surplus: const {'unit-9'},
    );

    expect(find.text('Recibido'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Sobrante'), findsOneWidget);
    // Un bulto por fila (2 esperados + 1 sobrante).
    expect(find.textContaining('Producto '), findsNWidgets(3));
  });

  testWidgets('muestra la ubicación en estante capturada para el bulto', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      expected: const ['unit-1'],
      received: const {'unit-1'},
      surplus: const {},
    );

    container
        .read(shelfLocationsProvider.notifier)
        .setLocation('unit-1', 'Pasillo 3 · B2');
    await tester.pumpAndSettle();

    expect(find.text('Estante: Pasillo 3 · B2'), findsOneWidget);
  });

  testWidgets('con cientos de productos solo arma las filas visibles', (
    tester,
  ) async {
    await _pump(
      tester,
      expected: [for (var i = 0; i < 300; i++) 'unit-$i'],
      received: const {},
      surplus: const {},
    );

    final built = find.byType(UnitProductRow).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(40));
  });
}
