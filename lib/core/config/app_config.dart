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

  /// Dónde actualizar la app cuando el backend exige una versión mínima
  /// (Play Store, MDM o link de descarga). Vacía = la pantalla de bloqueo pide
  /// avisar al supervisor en vez de mostrar el botón.
  static const String appUpdateUrl = String.fromEnvironment('APP_UPDATE_URL');

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

  /// Credenciales de Firebase Cloud Messaging (push). Se cargan desde
  /// `config/<entorno>.json` (`--dart-define-from-file`), sin google-services.json:
  /// salen de la consola de Firebase → Configuración del proyecto → app Android.
  /// Vacías = push desactivado (la app funciona igual, sin avisos push).
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  /// App iOS registrada en el mismo proyecto de Firebase (consola → app iOS,
  /// valores de su `GoogleService-Info.plist`). En iOS se usa este appId en vez
  /// de [firebaseAppId]; vacío = sin push en iOS. La API key de iOS es otra
  /// (Firebase la restringe por plataforma); vacía = se usa [firebaseApiKey].
  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );
  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );

  /// ¿Están las cuatro credenciales de Firebase? Si no, el push no arranca.
  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
