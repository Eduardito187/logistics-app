/// Contrato de autenticación de la app interna. La capa `data` lo implementa;
/// la capa `presentation` sólo lo conoce a través de los casos de uso.
abstract interface class AuthRepository {
  /// Autentica contra la puerta `/app/*` (A-02): usuario + contraseña +
  /// dispositivo → token Sanctum. Resuelve el rol operativo, abre la sesión
  /// y refresca las claves de etiquetas. Lanza `ApiException` ante un error.
  Future<void> login({required String email, required String password});
}
