import '../../../core/api/export.dart';

/// Kilómetros recorridos en la ruta de hoy: diferencia entre el odómetro de
/// LLEGADA (`arrival`) y el de SALIDA (`departure`) del día.
///
/// - [traveledKm]: `arrival − departure` cuando hay ambas lecturas del día y la
///   llegada no es menor que la salida; `null` si falta alguna o si la llegada
///   es menor que la salida (nunca negativo).
/// - [departureKm] / [arrivalKm]: los km que sí haya, para poder mostrar un
///   mensaje parcial ("Salida: X km, falta llegada").
typedef RouteKmToday = ({int? traveledKm, int? departureKm, int? arrivalKm});

/// Calcula los km recorridos de la ruta del día de [now] (zona local): toma la
/// lectura de SALIDA y la de LLEGADA más recientes del mismo día (mismo
/// año/mes/día que `readAt` en local) y devuelve su diferencia. Nunca lanza.
///
/// Lecturas de otro día se ignoran; otras fuentes (`manual`, `refuel`…) también.
RouteKmToday routeKmToday(List<OdometerReading> readings, DateTime now) {
  final today = now.toLocal();
  OdometerReading? departure;
  OdometerReading? arrival;

  for (final reading in readings) {
    final readAt = reading.readAt.toLocal();
    final sameDay =
        readAt.year == today.year &&
        readAt.month == today.month &&
        readAt.day == today.day;
    if (!sameDay) continue;

    switch (reading.source) {
      case OdometerReadingSource.departure:
        if (departure == null || reading.readAt.isAfter(departure.readAt)) {
          departure = reading;
        }
      case OdometerReadingSource.arrival:
        if (arrival == null || reading.readAt.isAfter(arrival.readAt)) {
          arrival = reading;
        }
      default:
        break;
    }
  }

  final departureKm = departure?.km;
  final arrivalKm = arrival?.km;
  final hasBoth = departureKm != null && arrivalKm != null;
  final traveledKm = (hasBoth && arrivalKm >= departureKm)
      ? arrivalKm - departureKm
      : null;

  return (
    traveledKm: traveledKm,
    departureKm: departureKm,
    arrivalKm: arrivalKm,
  );
}
