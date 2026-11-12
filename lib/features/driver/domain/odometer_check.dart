import '../../../core/api/export.dart';

/// Chequeo local del odómetro antes de enviarlo: el kilometraje solo AVANZA
/// (nunca retrocede). Es el mismo guard que aplica el backend, adelantado en la
/// app para evitar un viaje de red y dar un aviso claro en terreno (p. ej. la
/// lectura de llegada no puede ser menor que la de salida).
///
/// Devuelve el mayor kilometraje ya registrado si [km] es MENOR que ese valor
/// (es decir, la lectura retrocede y debe rechazarse); `null` si [km] es válido
/// (mayor o igual al último) o si no hay lecturas previas.
int? odometerBelowLast(int km, List<OdometerReading> readings) {
  if (readings.isEmpty) return null;
  var maxKm = readings.first.km;
  for (final r in readings) {
    if (r.km > maxKm) maxKm = r.km;
  }
  return km < maxKm ? maxKm : null;
}
