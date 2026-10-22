import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/auth/session.dart';
import 'core/brand/boot_splash_gate.dart';
import 'core/auth/token_store.dart';
import 'core/background/background_sync.dart';
import 'core/monitoring/crash_reporter.dart';
import 'core/monitoring/crash_reporting_init.dart';
import 'core/monitoring/crashlytics_failure_reporter.dart';
import 'core/network/auth_headers.dart';
import 'core/offline/failure_reporter.dart';
import 'core/version/app_build_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Teléfonos de 1 GB de RAM: la caché de imágenes por defecto (100 MB / 1000
  // imágenes) compite con el mapa y la cámara. 40 MB alcanza para tiles,
  // fotos de evidencia ya reducidas e íconos.
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 40 << 20
    ..maximumSize = 80;

  // Formatos de fecha/número en español (America/La_Paz) para toda la app.
  await initializeDateFormatting('es');

  // Errores en terreno (Crashlytics). Sin FIREBASE_* queda no-op.
  final crashReporter = await initCrashReporting();

  // Subida de la cola offline en segundo plano aunque la app esté cerrada
  // (WorkManager / BGTask). Nunca debe impedir que la app abra.
  try {
    await initBackgroundSync();
  } on Object catch (error, stack) {
    unawaited(crashReporter.recordError(error, stack, reason: 'init_bg_sync'));
  }

  final container = ProviderContainer(
    overrides: [
      crashReporterProvider.overrideWithValue(crashReporter),
      // Acciones rechazadas por el backend: invisibles para el usuario, pero
      // reportadas (sin datos personales) para la torre de control.
      failureReporterProvider.overrideWith(
        (ref) => CrashlyticsFailureReporter(ref.watch(crashReporterProvider)),
      ),
    ],
  );

  // Versión instalada lista antes del primer request (X-App-Version).
  await container.read(appBuildInfoProvider.notifier).ensureLoaded();

  // El identificador de dispositivo acompaña a cada escaneo y al Bearer de la
  // puerta /app/*. Se genera una sola vez y se carga antes del primer request.
  final deviceId = await container.read(tokenStoreProvider).deviceId();
  container.read(authHeadersProvider.notifier).setDeviceId(deviceId);

  // Sesión persistente: si había una sesión guardada se reabre logueado (sin
  // pasar por el login y sin red), como WhatsApp. Antes de runApp para que el
  // router arranque ya con la sesión y no parpadee el login.
  await container.read(sessionProvider.notifier).restore();

  // Lo que quedó pendiente (app cerrada sin señal) se sube al arrancar; sin
  // red, se agenda la subida en segundo plano.
  unawaited(drainOnStartup(container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      // Splash animado one-shot: se muestra una vez al arranque y luego entrega
      // la app. Va acá (no en el builder de MaterialApp) para que el Lottie se
      // cree una sola vez y no recargue en cada navegación/rebuild.
      child: const BootSplashGate(app: LogisticsApp()),
    ),
  );
}
