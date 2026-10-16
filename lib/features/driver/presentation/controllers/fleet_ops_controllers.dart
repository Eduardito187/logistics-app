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

/// Cargas de combustible recientes del vehículo seleccionado (más nuevas primero).
final vehicleRefuelsProvider = FutureProvider.autoDispose<List<Refuel>>((ref) {
  final vehicleId = ref.watch(assignedVehicleIdProvider);
  if (vehicleId == null) {
    throw const ApiException(status: 0, title: 'Sin vehículo asignado');
  }
  return ref.watch(listVehicleRefuelsProvider).call(vehicleId: vehicleId);
});

/// Lecturas de odómetro recientes del vehículo seleccionado (más nuevas primero).
final vehicleOdometerReadingsProvider =
    FutureProvider.autoDispose<List<OdometerReading>>((ref) {
      final vehicleId = ref.watch(assignedVehicleIdProvider);
      if (vehicleId == null) {
        throw const ApiException(status: 0, title: 'Sin vehículo asignado');
      }
      return ref.watch(listOdometerReadingsProvider).call(vehicleId: vehicleId);
    });

/// Mantenimiento preventivo por vencer o vencido de la flota (más urgente
/// primero).
final dueMaintenanceProvider =
    FutureProvider.autoDispose<List<DueMaintenanceItem>>(
      (ref) => ref.watch(listDueMaintenanceProvider).call(),
    );
