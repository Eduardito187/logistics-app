import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/usecases/get_delivery_state.dart';
import '../../domain/usecases/get_shipment_detail.dart';
import '../../domain/usecases/get_driver_route.dart';
import '../../domain/usecases/get_my_crew.dart';
import '../../domain/usecases/get_vehicle_cost_summary.dart';
import '../../domain/usecases/get_vehicle_utilization.dart';
import '../../domain/usecases/list_active_drivers.dart';
import '../../domain/usecases/list_vehicle_deliveries.dart';

/// Fecha de la ruta del día. Se normaliza a medianoche para la consulta por día.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _dateOnly(DateTime.now());

  void select(DateTime day) => state = _dateOnly(day);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

/// Asignación del chofer autenticado para la fecha activa: vehículo +
/// tripulación. El chofer NO elige; se le asigna. 404/sin asignación llega como
/// error del `AsyncValue` (lo maneja `DriverVehicleGate`).
final myCrewProvider = FutureProvider<MyCrew>(
  (ref) => ref.watch(getMyCrewProvider).call(ref.watch(selectedDateProvider)),
);

/// Id del vehículo ASIGNADO al chofer (derivado de la tripulación del día).
/// `null` mientras carga o cuando no hay asignación. Varias pantallas (ruta,
/// carga, GPS, resumen) dependen de este id.
///
/// `select`: solo notifica cuando cambia el id, no en cada recarga de la
/// tripulación (evita recalcular ruta/carga/costos sin necesidad).
final assignedVehicleIdProvider = Provider<String?>(
  (ref) =>
      ref.watch(myCrewProvider.select((crew) => crew.asData?.value.vehicle.id)),
);

/// Choferes activos (para firmar el checklist pre-salida). `autoDispose`: solo
/// lo usa el checklist; al salir se libera la lista.
final driversProvider = FutureProvider.autoDispose<List<Driver>>(
  (ref) => ref.watch(listActiveDriversProvider).call(),
);

/// Ruta del día del vehículo seleccionado (paradas ordenadas).
final driverRouteProvider = FutureProvider.autoDispose<DriverRoute>((ref) {
  final vehicleId = ref.watch(assignedVehicleIdProvider);
  final date = ref.watch(selectedDateProvider);
  if (vehicleId == null) {
    throw const ApiException(status: 0, title: 'Sin vehículo asignado');
  }
  return ref
      .watch(getDriverRouteProvider)
      .call(vehicleId: vehicleId, date: date);
});

/// Entregas asignadas al vehículo (hoja de ruta de carga).
final vehicleDeliveriesProvider = FutureProvider.autoDispose<List<Delivery>>((
  ref,
) {
  final vehicleId = ref.watch(assignedVehicleIdProvider);
  if (vehicleId == null) {
    throw const ApiException(status: 0, title: 'Sin vehículo asignado');
  }
  return ref.watch(listVehicleDeliveriesProvider).call(vehicleId: vehicleId);
});

/// Resumen de costos (TCO + costo por km) del vehículo en los últimos 30 días.
final vehicleCostSummaryProvider =
    FutureProvider.autoDispose<VehicleCostSummary>((ref) {
      final vehicleId = ref.watch(assignedVehicleIdProvider);
      if (vehicleId == null) {
        throw const ApiException(status: 0, title: 'Sin vehículo asignado');
      }
      final to = DateTime.now();
      final from = to.subtract(const Duration(days: 30));
      return ref
          .watch(getVehicleCostSummaryProvider)
          .call(vehicleId: vehicleId, from: from, to: to);
    });

/// Detalle del envío de una parada: teléfono del cliente y productos. Se usa en
/// la pantalla de entrega en curso.
final shipmentDetailProvider = FutureProvider.autoDispose
    .family<Shipment, String>((ref, shipmentId) {
      return ref.watch(getShipmentDetailProvider).call(shipmentId: shipmentId);
    });

/// Estado detallado de la entrega de un envío/parada (status + escaneos).
/// Lectura por envío; se usa en el detalle de parada para mostrar el estado real
/// de la entrega más allá del estado de la parada en la hoja de ruta.
final deliveryStateProvider = FutureProvider.autoDispose
    .family<Delivery, String>((ref, shipmentId) {
      return ref.watch(getDeliveryStateProvider).call(shipmentId: shipmentId);
    });

/// Utilización del vehículo en los últimos 30 días. El backend la devuelve como
/// un objeto libre (`data` dinámico); se expone como mapa para mostrar sus
/// métricas sin acoplarse a un esquema fijo.
final vehicleUtilizationProvider =
    FutureProvider.autoDispose<Map<String, Object?>>((ref) {
      final vehicleId = ref.watch(assignedVehicleIdProvider);
      if (vehicleId == null) {
        throw const ApiException(status: 0, title: 'Sin vehículo asignado');
      }
      final to = DateTime.now();
      final from = to.subtract(const Duration(days: 30));
      return ref
          .watch(getVehicleUtilizationProvider)
          .call(vehicleId: vehicleId, from: from, to: to);
    });
