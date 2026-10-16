/// Cabeceras de autenticación vigentes, en memoria, para que el interceptor de
/// Dio no tenga que leer almacenamiento seguro en cada request.
///
/// La sesión las actualiza al iniciar y cerrar sesión; el interceptor las lee.
/// El estado se gestiona con `AuthHeadersNotifier` (network/auth_headers.dart).
class AuthHeaders {
  const AuthHeaders({this.bearerToken, this.deviceId});

  final String? bearerToken;
  final String? deviceId;

  AuthHeaders copyWith({
    String? bearerToken,
    String? deviceId,
    bool clearToken = false,
  }) {
    return AuthHeaders(
      bearerToken: clearToken ? null : (bearerToken ?? this.bearerToken),
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
