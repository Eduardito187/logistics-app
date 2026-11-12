import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/vehicle.dart';
import 'package:logistics_app/features/picking/data/available_vehicles.dart';
import 'package:logistics_app/features/picking/presentation/widgets/assign_lane_dialog.dart';

// Diálogo de asignación de vehículo. Se ELIGE de la flota real (no texto libre):
// escribir cualquier placa rompía el flujo (el tracking iba a un camión
// inexistente). Devuelve la placa elegida por Navigator.pop (o null si cancela).

const _vehicles = <Vehicle>[
  Vehicle(
    id: 'v1',
    plate: '904U10',
    capacityKg: 4144,
    capacityM3: 32.7,
    status: 'available',
  ),
  Vehicle(
    id: 'v2',
    plate: '131O17',
    capacityKg: 3026,
    capacityM3: 31.8,
    status: 'in_service',
  ),
  Vehicle(
    id: 'v3',
    plate: '161W94',
    capacityKg: 2063,
    capacityM3: 15.8,
    status: 'maintenance',
  ),
];

/// Abre el diálogo con una flota [vehicles] (o un future que [fail]a) y deja el
/// resultado en `box[0]` al cerrarse.
Future<void> _open(
  WidgetTester tester,
  List<Object?> box, {
  String? initial,
  List<Vehicle> vehicles = _vehicles,
  bool fail = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        availableVehiclesProvider.overrideWith(
          (ref) async => fail ? throw Exception('boom') : vehicles,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                box[0] = await showDialog<Vehicle>(
                  context: context,
                  builder: (_) => AssignLaneDialog(initial: initial),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista los vehículos de la flota (placa + estado)', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    expect(find.text('Vehículo de reparto'), findsOneWidget);
    expect(find.text('904U10'), findsOneWidget);
    expect(find.text('131O17'), findsOneWidget);
    expect(find.textContaining('Disponible'), findsWidgets);
  });

  testWidgets('tocar un vehículo devuelve el VEHÍCULO (con su id)', (
    tester,
  ) async {
    // Devuelve el Vehicle, no solo la placa: hace falta el `id` para atar el
    // pedido al vehículo en el backend.
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.tap(find.text('904U10'));
    await tester.pumpAndSettle();

    expect(find.byType(AssignLaneDialog), findsNothing);
    expect((box[0]! as Vehicle).id, 'v1');
    expect((box[0]! as Vehicle).plate, '904U10');
  });

  testWidgets(
    'NO se puede escribir una placa libre: solo se elige de la lista',
    (tester) async {
      final box = <Object?>[#pending];
      await _open(tester, box);

      // El buscador FILTRA; no crea placas. Buscar algo inexistente no asigna.
      await tester.enterText(find.byType(TextField), 'ZZZ-999');
      await tester.pumpAndSettle();

      expect(find.text('904U10'), findsNothing);
      expect(find.textContaining('Ningún vehículo coincide'), findsOneWidget);
      // No hay botón "Guardar" para confirmar texto libre.
      expect(find.text('Guardar'), findsNothing);
      expect(box[0], #pending);
    },
  );

  testWidgets('el buscador filtra por placa', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.enterText(find.byType(TextField), '131');
    await tester.pumpAndSettle();

    expect(find.text('131O17'), findsOneWidget);
    expect(find.text('904U10'), findsNothing);
  });

  testWidgets('"Cancelar" cierra devolviendo null', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AssignLaneDialog), findsNothing);
    expect(box[0], isNull);
  });

  testWidgets('resalta el vehículo ya asignado (initial)', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box, initial: '131O17');

    // La placa inicial aparece en la lista (se marca con un check).
    expect(find.text('131O17'), findsOneWidget);
  });

  testWidgets('flota vacía: lo dice y no hay nada para asignar', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box, vehicles: const []);

    expect(find.text('No hay vehículos en la flota.'), findsOneWidget);
  });

  testWidgets('error de carga: avisa y ofrece reintentar', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box, fail: true);

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('sin texto libre ni escaneo: solo selección', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    expect(find.text('Guardar'), findsNothing);
    expect(find.text('Escanear'), findsNothing);
  });
}
