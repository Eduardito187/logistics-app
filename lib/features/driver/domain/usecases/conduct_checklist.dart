import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_repository_impl.dart';
import '../repositories/fleet_repository.dart';

/// Command (CQRS): registra el checklist pre-salida del camión (escritura
/// directa a la red). Devuelve el detalle del registro (incluido su `status`).
class ConductChecklist {
  const ConductChecklist(this._repo);

  final FleetRepository _repo;

  Future<Data5?> call({
    required String vehicleId,
    required String driverId,
    required Map<String, bool> items,
    required DateTime performedOn,
    String? notes,
  }) => _repo.conductPreTripChecklist(
    ConductPreTripChecklistRequest(
      vehicleId: vehicleId,
      driverId: driverId,
      items: items,
      performedOn: performedOn,
      notes: notes,
    ),
  );
}

final conductChecklistProvider = Provider<ConductChecklist>(
  (ref) => ConductChecklist(ref.watch(fleetRepositoryProvider)),
);
