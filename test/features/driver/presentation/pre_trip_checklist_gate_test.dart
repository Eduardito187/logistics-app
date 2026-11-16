import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/inspection_history_controller.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_actions_bar.dart';

import '../support/driver_test_support.dart';

// BLOQUEO PRE-SALIDA: el chofer no puede empezar a entregar si la inspección
// (checklist) del camión de esta salida está pendiente.

PreTripChecklist _checklist({DateTime? performedOn, String? routeId}) =>
    PreTripChecklist(performedOn: performedOn, routeId: routeId);

// `List<Object>` porque flutter_riverpod no expone públicamente el tipo
// `Override`; se castea al pasarlo (igual que en el soporte del chofer).
ProviderContainer _container(List<Object> overrides) {
  final container = ProviderContainer(overrides: overrides.cast());
  addTearDown(container.dispose);
  // Mantiene vivo el grafo (autoDispose) mientras se resuelven los futures.
  container.listen(preTripChecklistPendingProvider, (_, _) {});
  return container;
}

Future<bool> _pending(
  ProviderContainer container, {
  required String vehicleId,
}) async {
  await container.read(driverRouteProvider.future);
  await container.read(inspectionHistoryProvider(vehicleId).future);
  return container.read(preTripChecklistPendingProvider);
}

void main() {
  group('preTripChecklistPendingProvider', () {
    test('sin vehículo asignado NO bloquea (fail-open)', () {
      final container = _container([
        assignedVehicleIdProvider.overrideWithValue(null),
      ]);
      expect(container.read(preTripChecklistPendingProvider), isFalse);
    });

    test('modo diario: sin inspección hoy, bloquea', () async {
      final container = _container([
        assignedVehicleIdProvider.overrideWithValue('v1'),
        driverRouteProvider.overrideWith((ref) async => buildRoute(id: 'r1')),
        inspectionHistoryProvider(
          'v1',
        ).overrideWith((ref) async => const <PreTripChecklist>[]),
      ]);
      expect(await _pending(container, vehicleId: 'v1'), isTrue);
    });

    test('modo diario: con inspección de hoy, no bloquea', () async {
      final container = _container([
        assignedVehicleIdProvider.overrideWithValue('v1'),
        driverRouteProvider.overrideWith((ref) async => buildRoute(id: 'r1')),
        inspectionHistoryProvider('v1').overrideWith(
          (ref) async => [_checklist(performedOn: DateTime.now())],
        ),
      ]);
      expect(await _pending(container, vehicleId: 'v1'), isFalse);
    });

    test('modo por ruta: inspección de OTRA ruta, bloquea', () async {
      final container = _container([
        assignedVehicleIdProvider.overrideWithValue('v1'),
        driverRouteProvider.overrideWith((ref) async => buildRoute(id: 'r1')),
        inspectionHistoryProvider('v1').overrideWith(
          (ref) async => [
            _checklist(performedOn: DateTime.now(), routeId: 'otra-ruta'),
          ],
        ),
      ]);
      expect(await _pending(container, vehicleId: 'v1'), isTrue);
    });

    test('modo por ruta: inspección de ESTA ruta, no bloquea', () async {
      final container = _container([
        assignedVehicleIdProvider.overrideWithValue('v1'),
        driverRouteProvider.overrideWith((ref) async => buildRoute(id: 'r1')),
        inspectionHistoryProvider('v1').overrideWith(
          (ref) async => [
            _checklist(performedOn: DateTime.now(), routeId: 'r1'),
          ],
        ),
      ]);
      expect(await _pending(container, vehicleId: 'v1'), isFalse);
    });
  });

  group('DeliveryActionsBar', () {
    testWidgets('pendiente → muestra el CTA de inspección, no "Entregar"', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        overrides: [preTripChecklistPendingProvider.overrideWithValue(true)],
        child: DeliveryActionsBar(stop: buildStop(orderReference: 'PED-1')),
      );

      expect(find.text('Hacer inspección pre-salida'), findsOneWidget);
      expect(find.text('Entregar'), findsNothing);
      expect(find.text('No se pudo'), findsNothing);
    });

    testWidgets('sin pendiente → muestra las acciones de entrega', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        overrides: [preTripChecklistPendingProvider.overrideWithValue(false)],
        child: DeliveryActionsBar(stop: buildStop(orderReference: 'PED-1')),
      );

      expect(find.text('Entregar'), findsOneWidget);
      expect(find.text('Hacer inspección pre-salida'), findsNothing);
    });
  });
}
