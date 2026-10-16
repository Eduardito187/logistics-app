import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/assignment.dart';
import '../../../../core/api/models/corridor_type.dart';
import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Query: sugiere clase de vehículo y tarifa según el volumen (m³) del corredor.
class AssignForVolume {
  const AssignForVolume(this._repo);

  final CarrierRepository _repo;

  Future<Assignment> call({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required double volumeM3,
  }) => _repo.assignForVolume(
    corridorFrom: corridorFrom,
    corridorTo: corridorTo,
    corridorType: corridorType,
    volumeM3: volumeM3,
  );
}

final assignForVolumeProvider = Provider<AssignForVolume>(
  (ref) => AssignForVolume(ref.watch(carrierRepositoryProvider)),
);
