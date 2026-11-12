import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/due_maintenance_item.dart';
import '../../domain/usecases/get_current_fuel_price.dart';
import '../../domain/usecases/list_due_maintenance.dart';
import '../../domain/usecases/list_odometer_readings.dart';
import '../../domain/usecases/list_vehicle_refuels.dart';
import 'driver_controllers.dart';

/// Precio de combustible vigente para un tipo de combustible. Se usa como ayuda
/// al cargar combustible (prellenar el precio por litro). Family por `FuelType`
/// para que el formulario reaccione al tipo elegido.
final currentFuelPriceProvider = FutureProvider.autoDispose
    .family<FuelPrice, FuelType>((ref, fuelType) {
      return ref.watch(getCurrentFuelPriceProvider).call(fuelType: fuelType);
    });

/// Ventana de las tarjetas de "recientes" (cargas de combustible y lecturas de
/// odómetro): las tarjetas muestran como máximo 10 registros, así que basta el
/// último mes. Sin rango el backend devuelve el historial COMPLETO del camión
/// (años de registros) para pintar diez filas.
const int recentHistoryDays = 30;

/// Rango de un solo día de calendario (hoy): `from == to`. Se usa para los
/// kilómetros de hoy en "Mi día", que solo mira las lecturas de salida/llegada
/// del día.
///
/// Las fechas se arman a medianoche LOCAL a propósito: `DateQueryInterceptor`
/// recorta ese valor a `Y-m-d`, que es el formato de fecha que espera el
/// backend (con la hora actual respondería 422/500).
({DateTime from, DateTime to}) todayRange([DateTime? now]) {
  final today = now ?? DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  return (from: day, to: day);
}

/// Rango de los últimos [recentHistoryDays] días, hasta hoy inclusive.
({DateTime from, DateTime to}) recentRange([DateTime? now]) {
  final to = todayRange(now).to;
  return (from: to.subtract(const Duration(days: recentHistoryDays)), to: to);
}

/// Cargas de combustible del último mes del vehículo seleccionado (más nuevas
/// primero). Si el camión no cargó en el último mes la lista viene VACÍA: es un
/// resultado válido (estado vacío), no un error.
final vehicleRefuelsProvider = FutureProvider.autoDispose<List<Refuel>>((ref) {
  final vehicleId = ref.watch(assignedVehicleIdProvider);
  if (vehicleId == null) {
    throw const ApiException(status: 0, title: 'Sin vehículo asignado');
  }
  final range = recentRange();
  return ref
      .watch(listVehicleRefuelsProvider)
      .call(vehicleId: vehicleId, from: range.from, to: range.to);
});

/// Lecturas de odómetro del último mes del vehículo seleccionado (más nuevas
/// primero). Alcanza para las "lecturas recientes" y para el guard de odómetro
/// que no retrocede (el último registro del mes); el backend valida igual.
/// Lista vacía = camión sin lecturas en el último mes, no un error.
final vehicleOdometerReadingsProvider =
    FutureProvider.autoDispose<List<OdometerReading>>((ref) {
      final vehicleId = ref.watch(assignedVehicleIdProvider);
      if (vehicleId == null) {
        throw const ApiException(status: 0, title: 'Sin vehículo asignado');
      }
      final range = recentRange();
      return ref
          .watch(listOdometerReadingsProvider)
          .call(vehicleId: vehicleId, from: range.from, to: range.to);
    });

/// Lecturas de odómetro SOLO de hoy: lo único que necesitan los kilómetros
/// recorridos de la ruta del día ("Mi día"). Antes esa tarjeta bajaba el
/// historial completo del camión para calcular una resta.
final todayOdometerReadingsProvider =
    FutureProvider.autoDispose<List<OdometerReading>>((ref) {
      final vehicleId = ref.watch(assignedVehicleIdProvider);
      if (vehicleId == null) {
        throw const ApiException(status: 0, title: 'Sin vehículo asignado');
      }
      final range = todayRange();
      return ref
          .watch(listOdometerReadingsProvider)
          .call(vehicleId: vehicleId, from: range.from, to: range.to);
    });

/// Mantenimiento preventivo por vencer o vencido de la flota (más urgente
/// primero).
final dueMaintenanceProvider =
    FutureProvider.autoDispose<List<DueMaintenanceItem>>(
      (ref) => ref.watch(listDueMaintenanceProvider).call(),
    );
