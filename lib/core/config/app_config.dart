/// Configuración de la app, inyectada en build con `--dart-define`.
///
/// Ejemplo:
///   flutter run --dart-define=API_BASE_URL=https://logistics.dismac.com.bo/api/v1 \
///               --dart-define=LABEL_PUBLIC_KEYS=1:zOoO3DEULPdeVHmozqu0xm6E8njSdpO0jIZN7y+K/yo=
class AppConfig {
  const AppConfig._();

  /// Por defecto apunta al docker-compose del backend visto desde el emulador de Android.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8110/api/v1',
  );

  /// Claves públicas Ed25519 de etiquetas, formato "id:base64,id:base64".
  /// Son públicas: pueden ir en el binario sin riesgo.
  static const String labelPublicKeys = String.fromEnvironment(
    'LABEL_PUBLIC_KEYS',
  );
}
