import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/auth/session.dart';
import 'core/auth/token_store.dart';
import 'core/background/background_sync.dart';
import 'core/background/ui_alive.dart';
import 'core/push/push_controller.dart';
import 'core/monitoring/crash_reporter.dart';
import 'core/monitoring/crash_reporting_init.dart';
import 'core/monitoring/crashlytics_failure_reporter.dart';
import 'core/network/auth_headers.dart';
import 'core/network/riverpod_retry.dart';
import 'core/offline/failure_reporter.dart';
import 'core/performance/device_memory.dart';
import 'core/performance/memory_pressure.dart';
import 'core/theme/high_contrast.dart';
import 'core/version/app_build_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Arranque en paralelo (cada espera suma al tiempo de apertura en gama baja):
  // memoria del equipo, formatos en español, Crashlytics (no-op sin
  // FIREBASE_*) y el almacén seguro leído de UNA vez (en Android es lo más
  // lento del arranque; corre en un hilo propio del plugin y se solapa con
  // Firebase). Token, sesión, dispositivo y preferencias salen de memoria.
  final tokenStore = TokenStore(const FlutterSecureStorage());
  final (deviceMemory, _, crashReporter, _) = await (
    DeviceMemory.load(),
    initializeDateFormatting('es'),
    initCrashReporting(),
    tokenStore.preload(),
  ).wait;

  // Teléfonos de 1 GB de RAM: la caché de imágenes por defecto (100 MB / 1000
  // imágenes) compite con el mapa y la cámara. El tope depende del equipo
  // (24 MB en gama baja, 40 MB en media, 64 MB en alta) y se libera memoria
  // cuando el sistema la pide.
  final budget = MemoryBudget.forDevice(deviceMemory);
  applyImageCacheBudget(budget);
  MemoryPressureObserver(budget: budget).attach();

  final container = ProviderContainer(
    // Reintentos de providers solo para fallas de red/5xx/429 (máx. 3). Sin
    // esto Riverpod 3 reintenta 10 veces (~38 s) cualquier error, incluso un
    // 404 "sin asignación", y la pantalla queda cargando.
    retry: appProviderRetry,
    overrides: [
      deviceMemoryProvider.overrideWithValue(deviceMemory),
      tokenStoreProvider.overrideWithValue(tokenStore),
      crashReporterProvider.overrideWithValue(crashReporter),
      // Acciones rechazadas por el backend: invisibles para el usuario, pero
      // reportadas (sin datos personales) para la torre de control.
      failureReporterProvider.overrideWith(
        (ref) => CrashlyticsFailureReporter(ref.watch(crashReporterProvider)),
      ),
    ],
  );

  // En paralelo (cada lectura de plataforma/almacén seguro cuesta decenas de
  // ms en gama baja): versión instalada (X-App-Version), identificador de
  // dispositivo (va en cada escaneo y en el Bearer) y la preferencia de alto
  // contraste (el primer cuadro sale con el tema correcto, sin parpadeo).
  final (_, deviceId, _) = await (
    container.read(appBuildInfoProvider.notifier).ensureLoaded(),
    container.read(tokenStoreProvider).deviceId(),
    container.read(highContrastProvider.notifier).ensureLoaded(),
  ).wait;
  container.read(authHeadersProvider.notifier).setDeviceId(deviceId);

  // Sesión persistente: si había una sesión guardada se reabre logueado (sin
  // pasar por el login y sin red), como WhatsApp. Antes de runApp para que el
  // router arranque ya con la sesión y no parpadee el login.
  await container.read(sessionProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LogisticsApp(),
    ),
  );

  // Después del primer cuadro (no demora la apertura): subida de la cola en
  // segundo plano aunque la app esté cerrada (WorkManager / BGTask) y, luego,
  // lo que quedó pendiente se sube ya; sin red, se agenda en segundo plano
  // (por eso WorkManager tiene que estar inicializado antes del drenado).
  unawaited(_afterFirstFrame(container, crashReporter));
}

Future<void> _afterFirstFrame(
  ProviderContainer container,
  CrashReporter crashReporter,
) async {
  // La tarea de fondo no duplica el drenado mientras la UI está a la vista.
  UiAliveBeacon().attach();
  // Push (Firebase Messaging: token, permisos, listeners) fuera del camino
  // del primer cuadro. La suscripción queda viva toda la app.
  await WidgetsBinding.instance.endOfFrame;
  container.listen(pushRegistrationProvider, (_, _) {});
  try {
    await initBackgroundSync();
  } on Object catch (error, stack) {
    unawaited(crashReporter.recordError(error, stack, reason: 'init_bg_sync'));
  }
  await drainOnStartup(container);
}
