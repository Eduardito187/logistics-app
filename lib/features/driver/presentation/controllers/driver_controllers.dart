import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/get_delivery_state.dart';
import '../../domain/usecases/get_shipment_detail.dart';
import '../../domain/usecases/get_shipment_units.dart';
import '../../domain/usecases/get_driver_route.dart';
import '../../domain/usecases/get_my_crew.dart';
import '../../domain/usecases/get_vehicle_cost_summary.dart';
import '../../domain/usecases/get_vehicle_utilization.dart';
import '../../domain/usecases/list_active_drivers.dart';
import '../../domain/usecases/list_vehicle_deliveries.dart';
import 'locally_settled_stops.dart';

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
///
/// NO es `autoDispose` a propósito: es un objeto chico que usan todas las
/// pantallas del chofer (gate, ruta, carga, GPS) y el rastreo automático;
/// liberarlo al cambiar de pantalla obligaría a pedirlo de nuevo a la red en
/// cada navegación (y sin señal dejaría al chofer bloqueado en el gate).
final myCrewProvider = FutureProvider<MyCrew>(
  (ref) => ref.watch(getMyCrewProvider).call(ref.watch(selectedDateProvider)),
);

/// Id del vehículo ASIGNADO al chofer (derivado de la tripulación del día).
/// `null` mientras carga o cuando no hay asignación. Varias pantallas (ruta,
/// carga, GPS, resumen) dependen de este id.
///
/// `select`: solo notifica cuando cambia el id, no en cada recarga de la
/// tripulación (evita recalcular ruta/carga/costos sin necesidad).
///
/// `.value` (no `.asData?.value`): durante una recarga o si la recarga falla
/// sin señal conserva el vehículo anterior; con `asData` el id pasaba a `null`
/// un instante y la ruta, la carga y el rastreo se caían en cada refresco.
final assignedVehicleIdProvider = Provider<String?>(
  (ref) => ref.watch(myCrewProvider.select((crew) => crew.value?.vehicle.id)),
);

/// Choferes activos (para firmar el checklist pre-salida). `autoDispose`: solo
/// lo usa el checklist; al salir se libera la lista.
final driversProvider = FutureProvider.autoDispose<List<Driver>>((ref) {
  ref.cacheFor(CacheTtl.long);
  return ref.watch(listActiveDriversProvider).call();
});

/// Ruta del día del vehículo seleccionado (paradas ordenadas).
///
/// Caché corta ([CacheTtl.short]): la usan casi todas las pantallas del chofer
/// (entrega en curso, mi ruta, mi día, rastreo); volver a una de ellas muestra
/// la ruta al instante sin spinner ni request. Al invalidarla (volver de un
/// POD, "Siguiente entrega") el dato anterior sigue visible mientras se
/// refresca.
final driverRouteProvider = FutureProvider.autoDispose<DriverRoute>((
  ref,
) async {
  ref.cacheFor(CacheTtl.short);
  final vehicleId = ref.watch(assignedVehicleIdProvider);
  final date = ref.watch(selectedDateProvider);
  if (vehicleId == null) {
    throw const ApiException(status: 0, title: 'Sin vehículo asignado');
  }
  final route = await ref
      .watch(getDriverRouteProvider)
      .call(vehicleId: vehicleId, date: date);
  // Lo que el backend ya devuelve resuelto deja de contarse como resuelto
  // localmente (fuera del build: después del await).
  ref.read(locallySettledStopsProvider.notifier).reconcile(route);
  return route;
});

/// Entregas asignadas al vehículo (hoja de ruta de carga).
final vehicleDeliveriesProvider = FutureProvider.autoDispose<List<Delivery>>((
  ref,
) {
  ref.cacheFor(CacheTtl.short);
  final vehicleId = ref.watch(assignedVehicleIdProvider);
  if (vehicleId == null) {
    throw const ApiException(status: 0, title: 'Sin vehículo asignado');
  }
  return ref.watch(listVehicleDeliveriesProvider).call(vehicleId: vehicleId);
});

/// Resumen de costos (TCO + costo por km) del vehículo en los últimos 30 días.
final vehicleCostSummaryProvider =
    FutureProvider.autoDispose<VehicleCostSummary>((ref) {
      ref.cacheFor(CacheTtl.long);
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
/// la pantalla de entrega en curso. Caché larga: teléfono, dirección y
/// productos no cambian durante el turno.
final shipmentDetailProvider = FutureProvider.autoDispose
    .family<Shipment, String>((ref, shipmentId) {
      ref.cacheFor(CacheTtl.long);
      return ref.watch(getShipmentDetailProvider).call(shipmentId: shipmentId);
    });

/// Estado detallado de la entrega de un envío/parada (status + escaneos).
/// Lectura por envío; se usa en el detalle de parada para mostrar el estado real
/// de la entrega más allá del estado de la parada en la hoja de ruta.
final deliveryStateProvider = FutureProvider.autoDispose
    .family<Delivery, String>((ref, shipmentId) {
      ref.cacheFor(CacheTtl.short);
      return ref.watch(getDeliveryStateProvider).call(shipmentId: shipmentId);
    });

/// Utilización del vehículo en los últimos 30 días. El backend la devuelve como
/// un objeto libre (`data` dinámico); se expone como mapa para mostrar sus
/// métricas sin acoplarse a un esquema fijo.
final vehicleUtilizationProvider =
    FutureProvider.autoDispose<Map<String, Object?>>((ref) {
      ref.cacheFor(CacheTtl.long);
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

/// Ids de los bultos esperados de un envío. El escaneo de carga/descarga lo
/// pide al abrir (sin esperarlo): si llegó, un bulto ajeno se rechaza al
/// instante y el aviso muestra "Bulto N/M"; sin señal no se valida en el
/// teléfono (el backend decide al sincronizar). Caché larga: los bultos de un
/// envío no cambian durante el turno.
final driverShipmentUnitsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, shipmentId) async {
      ref.cacheFor(CacheTtl.long);
      final units = await ref
          .watch(getDriverShipmentUnitsProvider)
          .call(shipmentId);
      return {for (final u in units) u.unitId};
    });
