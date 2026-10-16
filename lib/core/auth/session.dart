import 'user_role.dart';

// Se reexportan las piezas movidas por SRP (`SessionNotifier`/`sessionProvider`
// y `SessionExpiredNotifier`/`sessionExpiredProvider`) para no romper a quienes
// importan `auth/session.dart`.
export 'session_expired_notifier.dart';
export 'session_notifier.dart';

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
  });

  final String userName;
  final UserRole role;

  /// Token Bearer por usuario+dispositivo. `null` en el dev-login.
  final String? token;

  /// Permisos (abilities) del token, tal como los devuelve `/app/auth/me`.
  /// Vacío por defecto: dev-login, login sin `/me`, o `/me` caído (red/permiso).
  /// En ese caso se aplica degradación segura (ver [RoleHomeScreen]).
  final List<String> abilities;

  /// ¿La sesión tiene este permiso? Chequeo plano contra las abilities del
  /// token. Con abilities vacías devuelve `false`; la regla de "no ocultar
  /// cuando no sabemos" vive en la capa de UI, no acá.
  bool can(String ability) => abilities.contains(ability);
}
