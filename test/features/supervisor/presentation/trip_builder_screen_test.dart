import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/domain/trip_already_planned.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/trip_vehicle_picker.dart';
import 'package:logistics_app/features/supervisor/presentation/trip_builder_screen.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// Armar un viaje: el camión, los pedidos más cercanos que propone el backend,
// el orden que recomienda y sus avisos. La app no calcula cercanías.

TripCandidate _candidate(
  String id,
  String order, {
  double km = 1.2,
  bool fits = true,
  bool suggested = false,
  String? reason,
  StopTimeWindow? window,
}) => TripCandidate(
  shipmentId: id,
  unitsTotal: 1,
  fits: fits,
  suggested: suggested,
  orderReference: order,
  customerName: 'Cliente $order',
  shortAddress: 'Calle $order',
  distanceKmFromAnchor: km,
  fitsReason: fits ? null : reason,
  suggestedReason: suggested ? reason : null,
  timeWindow: window,
);

final _all = [
  _candidate('s1', 'SO-1', km: 0.8, suggested: true, reason: 'El más cercano'),
  _candidate(
    's2',
    'SO-2',
    km: 2.5,
    window: StopTimeWindow(
      from: DateTime(2026, 11, 16, 10),
      to: DateTime(2026, 11, 16, 12),
    ),
  ),
  _candidate('s3', 'SO-3', km: 9, fits: false, reason: 'Supera el peso'),
];

/// Backend falso: devuelve los que todavía no se eligieron.
TripCandidateList _near(List<String> selected, String query) =>
    TripCandidateList(
      data: [
        for (final c in _all)
          if (!selected.contains(c.shipmentId)) c,
      ],
      meta: ListMeta(
        count: 3,
        anchor: TripCandidateAnchor(
          kind: selected.isEmpty
              ? TripCandidateAnchorKind.node
              : TripCandidateAnchorKind.shipment,
          name: selected.isEmpty ? 'CD Santa Cruz' : 'SO-1',
        ),
        capacity: const TripCapacity(
          usedUnits: 1,
          usedKg: 120,
          usedM3: 1,
          maxKg: 3000,
        ),
      ),
    );

Future<void> _pump(WidgetTester tester, FakeSupervisorRepository repo) async {
  tester.view.physicalSize = const Size(1200, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const TripBuilderScreen()),
      GoRoute(
        path: '/supervisor/plans/:planId',
        builder: (_, state) =>
            Scaffold(body: Text('Plan ${state.pathParameters['planId']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supervisorRepositoryProvider.overrideWithValue(repo),
        tripVehiclePickerProvider.overrideWithValue(
          (_) async => (id: 'v1', plate: '904U10'),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickVehicle(WidgetTester tester) async {
  await tester.tap(find.text('Elegir camión'));
  await tester.pumpAndSettle();
}

Finder _addButton(String order) => find.descendant(
  of: find.ancestor(of: find.text('Pedido $order'), matching: find.byType(Row)),
  matching: find.text('Agregar'),
);

void main() {
  testWidgets('sin camión no pide nada al backend', (tester) async {
    final repo = FakeSupervisorRepository()..candidates = _near;
    await _pump(tester, repo);

    expect(find.text('Armar un viaje'), findsOneWidget);
    expect(repo.candidateCalls, isEmpty);
    expect(find.text('Guardar viaje'), findsNothing);
  });

  testWidgets('con el camión muestra los pedidos más cercanos a su base', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()..candidates = _near;
    await _pump(tester, repo);
    await _pickVehicle(tester);

    expect(find.text('Camión 904U10 · Cambiar'), findsOneWidget);
    expect(find.text('3. Pedidos cercanos a CD Santa Cruz'), findsOneWidget);
    expect(find.text('Pedido SO-1'), findsOneWidget);
    expect(find.text('A 0,8 km'), findsOneWidget);
    expect(find.text('Sugerido'), findsOneWidget);
    expect(find.text('El más cercano'), findsOneWidget);
    // La hora que eligió el cliente se ve antes de sumar el pedido.
    expect(find.text('El cliente pidió entre 10:00 y 12:00'), findsOneWidget);
    // El que no entra se explica y no se puede agregar.
    expect(find.text('No entra'), findsOneWidget);
    expect(find.text('Supera el peso'), findsOneWidget);
    final blocked = tester.widget<FilledButton>(
      find.ancestor(
        of: _addButton('SO-3'),
        matching: find.bySubtype<FilledButton>(),
      ),
    );
    expect(blocked.onPressed, isNull);
  });

  testWidgets('al sumar uno pide los cercanos a ESE pedido', (tester) async {
    final repo = FakeSupervisorRepository()..candidates = _near;
    await _pump(tester, repo);
    await _pickVehicle(tester);

    await tester.tap(_addButton('SO-1'));
    await tester.pumpAndSettle();

    expect(repo.candidateCalls.last, ['s1']);
    expect(find.text('2. Tu viaje · 1 parada'), findsOneWidget);
    expect(find.text('3. Pedidos cercanos a SO-1'), findsOneWidget);
    expect(find.text('Carga: 120 de 3000 kg'), findsOneWidget);
    // Con una sola parada todavía no hay orden que sugerir.
    expect(repo.suggestionCalls, isEmpty);
  });

  testWidgets('orden sugerido por el backend: se ofrece y se aplica', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..candidates = _near
      ..suggestion = const TripSequenceSuggestion(
        orderedShipmentIds: ['s2', 's1'],
        stops: [],
        distanceKm: 12.4,
        durationMinutes: 95,
        changed: true,
        warnings: [
          TripSequenceWarning(
            code: TripSequenceWarningCode.windowMissed,
            shipmentId: 's2',
            detail: 'x',
          ),
        ],
      );
    await _pump(tester, repo);
    await _pickVehicle(tester);
    await tester.tap(_addButton('SO-1'));
    await tester.pumpAndSettle();
    await tester.tap(_addButton('SO-2'));
    await tester.pumpAndSettle();

    expect(repo.suggestionCalls.last, ['s1', 's2']);
    expect(find.text('Recorrido 12,4 km · 1 h 35 min'), findsOneWidget);
    expect(
      find.text('Pedido SO-2: no se llega a la hora que pidió el cliente'),
      findsOneWidget,
    );

    await tester.tap(find.text('Usar el orden sugerido'));
    await tester.pumpAndSettle();

    // Las paradas quedan como dijo el backend, y se vuelve a consultar.
    expect(repo.suggestionCalls.last, ['s2', 's1']);
  });

  testWidgets('guardar crea el viaje con las paradas en orden y abre el plan', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..candidates = _near
      ..planValue = plan(id: 'p9', status: PlanStatus.draft);
    await _pump(tester, repo);
    await _pickVehicle(tester);
    await tester.tap(_addButton('SO-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar viaje · 1 parada'));
    await tester.pumpAndSettle();

    expect(repo.createdTrips.single.vehicleId, 'v1');
    expect(repo.createdTrips.single.shipmentIds, ['s1']);
    expect(find.text('Plan p9'), findsOneWidget);
  });

  testWidgets('si el camión ya tiene viaje ese día, abre ese plan', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..candidates = _near
      ..createTripError = const TripAlreadyPlanned('p-existente');
    await _pump(tester, repo);
    await _pickVehicle(tester);
    await tester.tap(_addButton('SO-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar viaje · 1 parada'));
    await tester.pumpAndSettle();

    expect(find.text('Plan p-existente'), findsOneWidget);
  });

  test('avisos del orden sugerido, en palabras', () {
    expect(
      tripWarningText(TripSequenceWarningCode.overCapacity),
      'supera la capacidad del camión',
    );
    expect(
      tripWarningText(TripSequenceWarningCode.missingLocation),
      'no tiene ubicación en el mapa',
    );
  });
}
