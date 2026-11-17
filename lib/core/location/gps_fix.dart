/// Punto GPS simple que acompaña a escaneos, POD y telemetría.
class GpsFix {
  const GpsFix({
    required this.lat,
    required this.lng,
    this.accuracy,
    this.speedMps,
    this.headingDeg,
  });

  final double lat;
  final double lng;

  /// Precisión horizontal en metros (`null` si el fix no la trae).
  final double? accuracy;

  /// Velocidad instantánea en metros por segundo (`null` si no se conoce).
  final double? speedMps;

  /// Rumbo de avance en grados 0–360 (`null` si no se conoce; p. ej. detenido).
  final double? headingDeg;
}
