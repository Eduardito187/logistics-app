import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'sync_runner.dart';
import 'sync_scheduler.dart';

// Pegamento con el plugin `workmanager` (Android WorkManager / iOS
// BGTaskScheduler). Solo lo importa `main.dart`; la lógica está en
// `sync_runner.dart` para poder testearla sin el plugin.

export 'sync_runner.dart' show drainOnStartup;

/// Punto de entrada del isolate de fondo.
///
/// Top-level y con `vm:entry-point` para que el AOT no lo elimine. NO levanta
/// Flutter UI: [runBackgroundSync] abre la base Drift y el cliente API en un
/// `ProviderContainer` propio, drena ambas colas y cierra todo. Liviano para
/// teléfonos de 1 GB.
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final pendingLeft = await runBackgroundSync();
    // En la tarea única, devolver `false` con pendientes hace que Android la
    // reintente con backoff exponencial. La periódica siempre "termina bien":
    // ya vuelve a correr sola cada 15 min.
    if (task == BackgroundSyncTasks.oneOff) return !pendingLeft;
    return true;
  });
}

/// Planificador real: tarea única con red, sin apilar (`keep`).
class WorkmanagerSyncScheduler implements SyncScheduler {
  const WorkmanagerSyncScheduler();

  @override
  Future<void> scheduleOneOff() async {
    try {
      await Workmanager().registerOneOffTask(
        BackgroundSyncTasks.oneOff,
        BackgroundSyncTasks.oneOff,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
      );
    } on Object {
      // Best-effort: el periódico y la reconexión igual drenan.
    }
  }
}

/// Inicializa `workmanager`, instala el planificador real y programa el
/// drenado periódico (cada 15 min como mínimo, solo con red). Llamar UNA vez
/// en `main()` antes de `runApp`. Idempotente: la periódica se registra con
/// `keep` (no se reprograma en cada arranque). Nunca lanza: si el plugin falla
/// la app sigue con el drenado en primer plano (reconexión + arranque).
Future<void> initBackgroundSync() async {
  try {
    await Workmanager().initialize(backgroundSyncDispatcher);
    BackgroundSyncRegistry.scheduler = const WorkmanagerSyncScheduler();
    await Workmanager().registerPeriodicTask(
      BackgroundSyncTasks.periodic,
      BackgroundSyncTasks.periodic,
      frequency: BackgroundSyncTasks.frequency,
      // La periódica es la red de seguridad: con batería baja espera (Android
      // la corre apenas se cargue). La única que se programa al encolar sin
      // red NO lleva esta restricción: lo recién escaneado sube igual.
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  } on Object catch (e) {
    debugPrint('initBackgroundSync: $e');
  }
}
