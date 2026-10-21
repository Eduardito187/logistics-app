import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import '../network/auth_headers.dart';
import '../offline/sync_maintenance.dart';
import 'sync_scheduler.dart';

// Lógica de sincronización fuera de la UI, SIN depender de `workmanager` (así
// se testea sin el plugin). El pegamento con el plugin está en
// `background_sync.dart`.

/// Un drenado completo en un isolate de fondo. Crea su propio contenedor con
/// [createContainer] (por defecto uno vacío), lo cierra al terminar (cierra
/// también la base Drift) y devuelve `true` si quedó algo pendiente.
///
/// Sin token guardado (nadie logueado) no sube nada: la cola pendiente espera
/// al próximo login del dispositivo (ver política en `SessionNotifier.signOut`).
/// Nunca lanza.
Future<bool> runBackgroundSync({
  ProviderContainer Function()? createContainer,
}) async {
  final container = (createContainer ?? ProviderContainer.new)();
  try {
    final store = container.read(tokenStoreProvider);
    final String? token;
    final String deviceId;
    try {
      token = await store.readToken();
      deviceId = await store.deviceId();
    } on Object {
      // Almacén seguro ilegible (p. ej. iPhone bloqueado con protección de
      // datos): se reintenta en la próxima ejecución.
      return true;
    }
    final maintenance = container.read(syncMaintenanceProvider);
    // La purga de `failed` viejos no necesita red ni sesión.
    await maintenance.purgeStale();
    if (token == null || token.isEmpty) {
      return await maintenance.hasPending();
    }
    container.read(authHeadersProvider.notifier)
      ..setDeviceId(deviceId)
      ..setToken(token);
    await maintenance.drainAll();
    return await maintenance.hasPending();
  } on Object catch (e) {
    debugPrint('runBackgroundSync: $e');
    return true;
  } finally {
    container.dispose();
  }
}

/// Drenado al abrir la app: purga `failed` viejos y, si hay pendientes, hay
/// sesión y hay red, sube ambas colas. Sin red programa la tarea única de
/// fondo. Llamar en `main()` DESPUÉS de `sessionProvider.notifier.restore()`
/// (necesita el Bearer en cabeceras) y sin `await` (no demora el primer frame):
///
/// ```dart
/// unawaited(drainOnStartup(container));
/// ```
///
/// [isOnline] se inyecta en tests; por defecto consulta `connectivity_plus`.
/// Nunca lanza.
Future<void> drainOnStartup(
  ProviderContainer container, {
  Future<bool> Function()? isOnline,
}) async {
  try {
    final maintenance = container.read(syncMaintenanceProvider);
    await maintenance.purgeStale();
    if (!await maintenance.hasPending()) return;
    final token = container.read(authHeadersProvider).bearerToken;
    if (token == null || token.isEmpty) return;
    final online = await (isOnline ?? _hasConnectivity)();
    if (!online) {
      // Sin red: que el sistema lo suba apenas vuelva (aunque se cierre la app).
      await container.read(syncSchedulerProvider).scheduleOneOff();
      return;
    }
    await maintenance.drainAll();
  } on Object catch (e) {
    debugPrint('drainOnStartup: $e');
  }
}

Future<bool> _hasConnectivity() async {
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}
