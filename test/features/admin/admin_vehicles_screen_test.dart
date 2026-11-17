import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/admin/data/admin_remote_data_source.dart';
import 'package:logistics_app/features/admin/domain/entities/admin_vehicle.dart';
import 'package:logistics_app/features/admin/domain/entities/maintenance_result.dart';
import 'package:logistics_app/core/widgets/paged.dart';
import 'package:logistics_app/features/admin/presentation/admin_vehicles_screen.dart';

import '../../support/button_finders.dart';

// Camiones del administrador: buscar por placa, filtrar por estado y mandar a
// mantenimiento (avisando si el camión tenía paradas pendientes).

AdminVehicle _vehicle(
  String id,
  String plate, {
  AdminVehicleStatus status = AdminVehicleStatus.available,
  bool? fit,
}) => AdminVehicle(id: id, plate: plate, status: status, fitToDispatch: fit);

/// Fuente de datos falsa: filtra en memoria como lo haría el servidor y
/// registra lo pedido.
class _FakeAdmin implements AdminRemoteDataSource {
  _FakeAdmin(
    this.vehicles, {
    this.result = const MaintenanceResult(),
    this.error,
  });

  final List<AdminVehicle> vehicles;
  final MaintenanceResult result;
  final ApiException? error;

  final List<({String query, AdminVehicleStatus? status, int page})> requests =
      [];
  final List<
    ({String id, MaintenanceType type, String? workshop, String? note})
  >
  sent = [];

  @override
  Future<Paged<AdminVehicle>> listVehicles({
    String query = '',
    AdminVehicleStatus? status,
    int page = 1,
  }) async {
    requests.add((query: query, status: status, page: page));
    if (error != null) throw error!;
    return Paged(
      items: [
        for (final v in vehicles)
          if ((status == null || v.status == status) &&
              v.displayPlate.toLowerCase().contains(query.toLowerCase()))
            v,
      ],
      hasMore: false,
    );
  }

  @override
  Future<Paged<Shipment>> listShipments({
    String query = '',
    String city = '',
    ShipmentStatus? status,
    int page = 1,
  }) async => const Paged(items: [], hasMore: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<MaintenanceResult> sendToMaintenance(
    String vehicleId, {
    required MaintenanceType type,
    String? workshop,
    String? note,
    String? reassignToVehicleId,
  }) async {
    sent.add((id: vehicleId, type: type, workshop: workshop, note: note));
    return result;
  }
}

Future<void> _pump(WidgetTester tester, _FakeAdmin fake) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminRemoteDataSourceProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: AdminVehiclesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final fleet = [
    _vehicle('v1', '904U10'),
    _vehicle('v2', '131O17', status: AdminVehicleStatus.inService),
    _vehicle('v3', '555ABC', status: AdminVehicleStatus.maintenance),
  ];

  testWidgets('lista los camiones con su estado', (tester) async {
    await _pump(tester, _FakeAdmin(fleet));

    expect(find.text('904U10'), findsOneWidget);
    expect(find.text('131O17'), findsOneWidget);
    expect(find.text('555ABC'), findsOneWidget);
    expect(find.text('3 resultados'), findsOneWidget);
    // El que ya está en mantenimiento no ofrece mandarlo de nuevo.
    expect(find.text('Mandar a mantenimiento'), findsNWidgets(2));
  });

  testWidgets('buscar por placa consulta al servidor', (tester) async {
    final fake = _FakeAdmin(fleet);
    await _pump(tester, fake);

    await tester.enterText(find.byType(TextField), '904');
    // Pausa del buscador antes de pedir.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(fake.requests.last.query, '904');
    expect(find.text('904U10'), findsOneWidget);
    expect(find.text('131O17'), findsNothing);
  });

  testWidgets('filtrar por estado vuelve a pedir la lista', (tester) async {
    final fake = _FakeAdmin(fleet);
    await _pump(tester, fake);

    // El estado es un select.
    await tester.tap(find.text('Todos los estados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('En mantenimiento').last);
    await tester.pumpAndSettle();

    expect(fake.requests.last.status, AdminVehicleStatus.maintenance);
    expect(find.text('555ABC'), findsOneWidget);
    expect(find.text('904U10'), findsNothing);
  });

  testWidgets('camión no apto se marca en rojo', (tester) async {
    await _pump(tester, _FakeAdmin([_vehicle('v1', '904U10', fit: false)]));

    expect(find.text('No apto para salir'), findsOneWidget);
  });

  testWidgets('mandar a mantenimiento avisa de los pedidos sin camión', (
    tester,
  ) async {
    final fake = _FakeAdmin([
      _vehicle('v1', '904U10'),
    ], result: const MaintenanceResult(pendingOrders: ['SO-1', 'SO-2']));
    await _pump(tester, fake);

    await tester.tap(find.text('Mandar a mantenimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preventivo'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Taller (opcional)'),
      'Taller Norte',
    );
    await tester.tap(
      findButtonWithText<FilledButton>('Mandar a mantenimiento'),
    );
    await tester.pumpAndSettle();

    expect(fake.sent.single.id, 'v1');
    expect(fake.sent.single.type, MaintenanceType.preventive);
    expect(fake.sent.single.workshop, 'Taller Norte');
    expect(find.text('Camión 904U10 en mantenimiento'), findsOneWidget);
    // Honestidad: los pedidos NO se reasignan solos.
    expect(
      find.textContaining('Quedaron 2 pedidos SIN camión'),
      findsOneWidget,
    );
    expect(find.textContaining('SO-1, SO-2'), findsOneWidget);
  });

  testWidgets('error del servidor: mensaje y reintento', (tester) async {
    await _pump(
      tester,
      _FakeAdmin(const [], error: const ApiException(status: 500, title: 'x')),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
