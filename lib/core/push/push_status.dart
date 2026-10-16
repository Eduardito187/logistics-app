import 'push_registration_state.dart';

// Se reexporta [PushRegistrationState] (movido a su propio archivo por SRP) para
// no romper a quienes importan `push/push_status.dart`.
export 'push_registration_state.dart';

/// Instantánea del estado de push. Transporta el token FCM para que la UI y el
/// coordinador puedan mostrarlo y actuar.
class PushStatus {
  const PushStatus({required this.state, this.token, this.message});

  /// Estado inicial: sin registro y sin token.
  const PushStatus.idle() : this(state: PushRegistrationState.idle);

  final PushRegistrationState state;

  /// Token FCM del dispositivo. `null` si no hay.
  final String? token;

  /// Mensaje legible para la UI ante un error o aviso.
  final String? message;

  bool get isRegistered =>
      state == PushRegistrationState.registered && (token?.isNotEmpty ?? false);

  /// Centinela para distinguir "no se pasó el campo" de "se pasó null". Sin esto,
  /// `message ?? this.message` hace que `copyWith(message: null)` conserve el
  /// mensaje viejo: tras un error y luego un registro exitoso, la tarjeta
  /// quedaba "Activo" pero seguía mostrando la línea de error roja.
  static const Object _unset = Object();

  PushStatus copyWith({
    PushRegistrationState? state,
    Object? token = _unset,
    Object? message = _unset,
  }) {
    return PushStatus(
      state: state ?? this.state,
      token: identical(token, _unset) ? this.token : token as String?,
      message: identical(message, _unset) ? this.message : message as String?,
    );
  }
}
