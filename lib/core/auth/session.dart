import '../api/models/node.dart';
import 'user_role.dart';

// Se reexportan las piezas movidas por SRP (`SessionNotifier`/`sessionProvider`
// y `SessionExpiredNotifier`/`sessionExpiredProvider`) para no romper a quienes
// importan `auth/session.dart`.
export 'session_expired_notifier.dart';
export 'session_notifier.dart';
export 'token_refresh_notifier.dart';

/// Datos de la sesión actual del usuario (modelo inmutable).
///
/// Se gestiona a través de `SessionNotifier` (auth/session_notifier.dart) y se
/// expone vía `sessionProvider`.
class Session {
  const Session({
    required this.userName,
    required this.role,
    this.token,
    this.abilities = const [],
    this.storeNode,
    this.tokenExpiresAt,
    this.tokenIssuedAt,
  });

  final String userName;
  final UserRole role;

  /// Token Bearer por usuario+dispositivo. `null` en el dev-login.
  final String? token;

  /// Permisos (abilities) del token, tal como los devuelve `/app/auth/me`.
  /// Vacío por defecto: dev-login, login sin `/me`, o `/me` caído (red/permiso).
  /// En ese caso se aplica degradación segura (ver [RoleHomeScreen]).
  final List<String> abilities;

  /// Tienda (nodo) a la que pertenece el usuario, según `/app/auth/me`.
  /// `null` para roles sin tienda o si el backend no la asignó. El rol tienda
  /// opera SOLO sobre este nodo (el backend lo exige con 403).
  final Node? storeNode;

  /// Vencimiento del token (`expires_at` del login o del refresh). `null` si el
  /// backend no lo informó o si el login no lo pasó: en ese caso el refresh
  /// proactivo cae a su política de respaldo (ver `TokenRefreshNotifier`).
  final DateTime? tokenExpiresAt;

  /// Momento en que se emitió el token vigente (login o último refresh). Lo usa
  /// el refresh proactivo para no renovar dos veces seguidas cuando no se
  /// conoce el vencimiento.
  final DateTime? tokenIssuedAt;

  /// ¿La sesión tiene este permiso? Chequeo plano contra las abilities del
  /// token. Con abilities vacías devuelve `false`; la regla de "no ocultar
  /// cuando no sabemos" vive en la capa de UI, no acá.
  bool can(String ability) => abilities.contains(ability);
}
