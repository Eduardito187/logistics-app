import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Opciones de Firebase armadas desde `config/<entorno>.json` (FIREBASE_*).
///
/// Así no hace falta `google-services.json` / `GoogleService-Info.plist` ni el
/// plugin de Gradle: para activar el push basta con completar las credenciales
/// del proyecto de Firebase (consola → Configuración del proyecto). En iOS se
/// usa el appId de la app iOS (`FIREBASE_IOS_APP_ID`) y, si está,
/// su API key (`FIREBASE_IOS_API_KEY`). `null` si faltan.
FirebaseOptions? firebaseOptionsFromConfig() => buildFirebaseOptions(
  platform: defaultTargetPlatform,
  apiKey: AppConfig.firebaseApiKey,
  iosApiKey: AppConfig.firebaseIosApiKey,
  androidAppId: AppConfig.firebaseAppId,
  iosAppId: AppConfig.firebaseIosAppId,
  iosBundleId: AppConfig.firebaseIosBundleId,
  messagingSenderId: AppConfig.firebaseMessagingSenderId,
  projectId: AppConfig.firebaseProjectId,
);

/// Arma las opciones según la plataforma. Separada de [AppConfig] (constantes
/// de compilación) para poder probar cada combinación.
@visibleForTesting
FirebaseOptions? buildFirebaseOptions({
  required TargetPlatform platform,
  required String apiKey,
  required String androidAppId,
  required String iosAppId,
  required String iosBundleId,
  required String messagingSenderId,
  required String projectId,
  String iosApiKey = '',
}) {
  final isIos = platform == TargetPlatform.iOS;
  final appId = isIos ? iosAppId : androidAppId;
  final key = isIos && iosApiKey.isNotEmpty ? iosApiKey : apiKey;
  if (key.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty) {
    return null;
  }
  return FirebaseOptions(
    apiKey: key,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    iosBundleId: isIos && iosBundleId.isNotEmpty ? iosBundleId : null,
  );
}
