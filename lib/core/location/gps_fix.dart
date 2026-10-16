/// Punto GPS simple que acompaña a escaneos, POD y telemetría.
class GpsFix {
  const GpsFix({required this.lat, required this.lng, this.accuracy});

  final double lat;
  final double lng;
  final double? accuracy;
}
