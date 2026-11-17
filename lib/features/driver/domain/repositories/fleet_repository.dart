import '../../../../core/api/export.dart';

/// Contrato de la flota para el chofer (módulo `fleet`): vehículos, choferes y
/// checklist pre-salida. La capa `data` lo implementa; la `presentation` lo usa
/// sólo vía casos de uso. Lanza `ApiException` ante un error.
abstract interface class FleetRepository {
  /// Asignación (vehículo + tripulación) del chofer autenticado. Sin fecha =
  /// asignación VIGENTE (la ruta en curso manda sobre el calendario; midnight-
  /// safe). Con fecha = ese día puntual. Lanza `ApiException` 404 si no hay
  /// asignación.
  Future<MyCrew> getMyCrew([DateTime? date]);

  /// Choferes activos (para firmar el checklist pre-salida).
  Future<List<Driver>> listActiveDrivers();

  /// Registra el checklist pre-salida del camión. Devuelve el detalle del
  /// registro (incluido su `status`), o `null` si el backend no lo devuelve.
  Future<PreTripChecklistResult?> conductPreTripChecklist(
    ConductPreTripChecklistRequest request,
  );
}
