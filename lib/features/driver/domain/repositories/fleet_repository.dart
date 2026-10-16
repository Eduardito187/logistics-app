import '../../../../core/api/export.dart';

/// Contrato de la flota para el chofer (módulo `fleet`): vehículos, choferes y
/// checklist pre-salida. La capa `data` lo implementa; la `presentation` lo usa
/// sólo vía casos de uso. Lanza `ApiException` ante un error.
abstract interface class FleetRepository {
  /// Asignación (vehículo + tripulación) del chofer autenticado para la fecha.
  /// Lanza `ApiException` con status 404 cuando no hay asignación.
  Future<MyCrew> getMyCrew(DateTime date);

  /// Choferes activos (para firmar el checklist pre-salida).
  Future<List<Driver>> listActiveDrivers();

  /// Registra el checklist pre-salida del camión. Devuelve el detalle del
  /// registro (incluido su `status`), o `null` si el backend no lo devuelve.
  Future<Data5?> conductPreTripChecklist(
    ConductPreTripChecklistRequest request,
  );
}
