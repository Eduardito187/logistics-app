/// Estado interno del gate de permiso de ubicación: verificando el permiso,
/// concedido (deja pasar al hijo) o denegado (bloquea con la pantalla que
/// manda a los ajustes del sistema).
enum LocationGateStatus { checking, granted, denied }
