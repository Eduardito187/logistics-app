import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identificadores de las tareas de sincronización en segundo plano.
///
/// En iOS el nombre único de la tarea periódica ES el identificador de
/// BGTaskScheduler: debe figurar en `BGTaskSchedulerPermittedIdentifiers`
/// (Info.plist) y registrarse en el AppDelegate.
abstract final class BackgroundSyncTasks {
  /// Tarea periódica (Android WorkManager / iOS BGAppRefreshTask).
  static const String periodic = 'bo.com.dismac.logisticsApp.sync';

  /// Tarea única al encolar sin red (Android: espera a tener red).
  static const String oneOff = 'bo.com.dismac.logisticsApp.sync.once';

  /// Frecuencia mínima que permite Android WorkManager.
  static const Duration frequency = Duration(minutes: 15);
}

/// Programa un drenado en segundo plano cuando quedó algo pendiente.
///
/// Esta interfaz NO importa `workmanager` a propósito: las colas (y sus tests)
/// dependen solo de ella. La implementación real vive en `background_sync.dart`
/// y se instala con `initBackgroundSync()` desde `main()`.
abstract interface class SyncScheduler {
  /// Pide un drenado único con restricción de red. Barato e idempotente: si ya
  /// hay uno programado, se conserva (no se apilan tareas).
  Future<void> scheduleOneOff();
}

/// No programa nada: en tests, dentro de la propia tarea de fondo o si el
/// plugin no se pudo inicializar.
class NoopSyncScheduler implements SyncScheduler {
  const NoopSyncScheduler();

  @override
  Future<void> scheduleOneOff() async {}
}

/// Planificador vigente del isolate. `initBackgroundSync()` lo reemplaza por
/// el de `workmanager`; por defecto es no-op.
abstract final class BackgroundSyncRegistry {
  static SyncScheduler scheduler = const NoopSyncScheduler();
}

final syncSchedulerProvider = Provider<SyncScheduler>(
  (ref) => BackgroundSyncRegistry.scheduler,
);
