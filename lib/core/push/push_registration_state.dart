/// Estado del registro push del dispositivo (UnifiedPush/ntfy, ADR 014).
///
/// La UI lo observa (vía [PushStatus]) para mostrar el indicador de push
/// (registrado / registrando / sin distribuidor / error).
enum PushRegistrationState {
  /// Aún no se intentó registrar (o no hay endpoint guardado).
  idle,

  /// Pidiendo endpoint al distribuidor; en curso.
  registering,

  /// Registrado: hay un endpoint válido del distribuidor.
  registered,

  /// No hay ningún distribuidor UnifiedPush instalado en el dispositivo.
  unavailable,

  /// El distribuidor rechazó el registro.
  failed,

  /// El dispositivo quedó dado de baja del distribuidor.
  unregistered,
}
