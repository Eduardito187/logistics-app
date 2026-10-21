/// Estado del registro push del dispositivo (Firebase Cloud Messaging).
///
/// La UI lo observa (vía `PushStatus`) para mostrar el indicador de push.
enum PushRegistrationState {
  /// Aún no se activó (o no hay token guardado).
  idle,

  /// Pidiendo permiso / token a FCM; en curso.
  registering,

  /// Registrado: hay un token FCM válido.
  registered,

  /// Push no configurado: faltan las credenciales de Firebase (config/*.json).
  unavailable,

  /// Falló el registro (permiso denegado, sin token o error de FCM).
  failed,
}
