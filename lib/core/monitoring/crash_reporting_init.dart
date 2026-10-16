import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../push/push_service.dart';
import 'crash_reporter.dart';
import 'crashlytics_crash_reporter.dart';

/// Arranca el reporte de errores en terreno y devuelve el [CrashReporter] a
/// usar en toda la app (se inyecta con `crashReporterProvider.overrideWithValue`).
///
/// - Sin credenciales FIREBASE_* en `config/*.json` → [NoopCrashReporter] y NO
///   se tocan los handlers globales: la app funciona igual, sin reportes.
/// - Con credenciales: inicializa Firebase (idempotente, compartido con push),
///   habilita la colección SOLO en release y engancha `FlutterError.onError` y
///   `PlatformDispatcher.instance.onError`.
/// - Cualquier fallo del plugin → [NoopCrashReporter]. Nunca lanza.
///
/// Los parámetros existen para tests; en producción se llama sin argumentos.
Future<CrashReporter> initCrashReporting({
  Future<bool> Function()? initFirebase,
  FirebaseCrashlytics Function()? crashlytics,
  bool collectionEnabled = kReleaseMode,
  bool installHandlers = true,
}) async {
  try {
    final ready = await (initFirebase ?? initFirebaseFromConfig)();
    if (!ready) return const NoopCrashReporter();
    final instance = (crashlytics ?? () => FirebaseCrashlytics.instance)();
    await instance.setCrashlyticsCollectionEnabled(collectionEnabled);
    final reporter = CrashlyticsCrashReporter(
      instance,
      enabled: collectionEnabled,
    );
    await reporter.setCustomKey(CrashKeys.env, AppConfig.env);
    if (installHandlers) installCrashHandlers(reporter);
    return reporter;
  } on Object catch (e) {
    debugPrint('Reporte de errores desactivado: $e');
    return const NoopCrashReporter();
  }
}

/// Engancha los handlers globales de errores al [reporter], encadenando los
/// handlers previos (así en debug se sigue viendo el error en consola).
void installCrashHandlers(CrashReporter reporter) {
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutterHandler?.call(details);
    reporter.recordFlutterError(details, fatal: true);
  };

  final dispatcher = PlatformDispatcher.instance;
  final previousPlatformHandler = dispatcher.onError;
  dispatcher.onError = (error, stack) {
    previousPlatformHandler?.call(error, stack);
    reporter.recordError(error, stack, fatal: true);
    // Manejado: evita que el motor lo vuelva a reportar como no capturado.
    return true;
  };
}
