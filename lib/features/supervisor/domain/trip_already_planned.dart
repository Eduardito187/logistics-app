/// El camión ya tiene un plan ese día (un plan por camión y día): el viaje
/// nuevo no se crea; hay que sumar las paradas a [planId].
class TripAlreadyPlanned implements Exception {
  const TripAlreadyPlanned(this.planId);

  final String planId;
}
