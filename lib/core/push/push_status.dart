import 'push_registration_state.dart';

// Se reexporta [PushRegistrationState] (movido a su propio archivo por SRP) para
// no romper a quienes importan `push/push_status.dart`.
export 'push_registration_state.dart';

/// Instantánea del estado de push. Transporta el endpoint y el distribuidor
/// elegido para que la UI y el coordinador puedan mostrarlos y actuar.
class PushStatus {
  const PushStatus({
    required this.state,
    this.endpoint,
    this.distributor,
    this.message,
  });

  /// Estado inicial: sin registro y sin endpoint.
  const PushStatus.idle() : this(state: PushRegistrationState.idle);

  final PushRegistrationState state;

  /// URL del endpoint entregado por el distribuidor (ntfy). `null` si no hay.
  final String? endpoint;

  /// Identificador del distribuidor UnifiedPush en uso (paquete Android).
  final String? distributor;

  /// Mensaje legible para la UI ante un error o aviso.
  final String? message;

  bool get isRegistered =>
      state == PushRegistrationState.registered &&
      (endpoint?.isNotEmpty ?? false);

  /// Centinela para distinguir "no se pasó el campo" de "se pasó null". Sin esto,
  /// `message ?? this.message` hace que `copyWith(message: null)` conserve el
  /// mensaje viejo: tras un error y luego un registro exitoso, la tarjeta
  /// quedaba "Activo" pero seguía mostrando la línea de error roja.
  static const Object _unset = Object();

  PushStatus copyWith({
    PushRegistrationState? state,
    Object? endpoint = _unset,
    Object? distributor = _unset,
    Object? message = _unset,
  }) {
    return PushStatus(
      state: state ?? this.state,
      endpoint: identical(endpoint, _unset)
          ? this.endpoint
          : endpoint as String?,
      distributor: identical(distributor, _unset)
          ? this.distributor
          : distributor as String?,
      message: identical(message, _unset) ? this.message : message as String?,
    );
  }
}
