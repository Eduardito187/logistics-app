/// Configuración de la app, inyectada en build con `--dart-define-from-file`.
///
/// Cada entorno vive en un JSON en `config/` (dev, staging, production) y se
/// pasa con un solo argumento:
///   flutter run --dart-define-from-file=config/dev.json
///
/// También se puede inyectar clave por clave con `--dart-define` (equivalente):
///   flutter run --dart-define=API_BASE_URL=https://logistics.dismac.com.bo/api/v1 \
///               --dart-define=LABEL_PUBLIC_KEYS=1:zOoO3DEULPdeVHmozqu0xm6E8njSdpO0jIZN7y+K/yo=
class AppConfig {
  const AppConfig._();

  /// Nombre del entorno activo: dev | staging | production.
  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// Por defecto apunta al docker-compose del backend visto desde el emulador de Android.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8110/api/v1',
  );

  /// Conveniencias para condicionar comportamiento por entorno.
  static bool get isProduction => env == 'production';
  static bool get isDev => env == 'dev';

  /// Claves públicas Ed25519 de etiquetas, formato "id:base64,id:base64".
  /// Son públicas: pueden ir en el binario sin riesgo.
  static const String labelPublicKeys = String.fromEnvironment(
    'LABEL_PUBLIC_KEYS',
  );

  /// Tiles del mapa OSM self-host (ADR 013/I-10). Sin Google. En desarrollo
  /// apunta al tile server público de OSM; en producción se pasa el propio.
  static const String mapTilesUrl = String.fromEnvironment(
    'MAP_TILES_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Endpoint ntfy/UnifiedPush por defecto (push sin Firebase, ADR 014).
  static const String pushEndpoint = String.fromEnvironment('PUSH_ENDPOINT');
}
