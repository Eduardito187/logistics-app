import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_data_source.dart';

/// Implementación del contrato de flota. Delega directamente en el data source.
class FleetRepositoryImpl implements FleetRepository {
  const FleetRepositoryImpl(this._remote);

  final FleetDataSource _remote;

  @override
  Future<MyCrew> getMyCrew(DateTime date) => _remote.getMyCrew(date);

  @override
  Future<List<Driver>> listActiveDrivers() => _remote.listActiveDrivers();

  @override
  Future<Data4?> conductPreTripChecklist(
    ConductPreTripChecklistRequest request,
  ) => _remote.conductPreTripChecklist(request);
}

final fleetRepositoryProvider = Provider<FleetRepository>(
  (ref) => FleetRepositoryImpl(ref.watch(fleetDataSourceProvider)),
);
