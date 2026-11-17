import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_repository_impl.dart';
import '../repositories/fleet_repository.dart';

/// Query (CQRS): asignación (vehículo + tripulación) del chofer autenticado.
/// El chofer no elige: se le asigna.
///
/// SIN fecha = asignación VIGENTE (midnight-safe): si el chofer tiene una ruta
/// EN CURSO de otro día, el backend devuelve ESA cuadrilla hasta que la ruta
/// cierre (la asignación la rige el ESTADO de la ruta, no el calendario). Así
/// una entrega larga o que cruza la medianoche no se le quita al chofer. Con
/// fecha explícita se consulta ese día puntual (p. ej. previsualización).
class GetMyCrew {
  const GetMyCrew(this._repo);

  final FleetRepository _repo;

  Future<MyCrew> call([DateTime? date]) => _repo.getMyCrew(date);
}

final getMyCrewProvider = Provider<GetMyCrew>(
  (ref) => GetMyCrew(ref.watch(fleetRepositoryProvider)),
);
