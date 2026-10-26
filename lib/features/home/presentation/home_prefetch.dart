import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../core/auth/user_role.dart';
import '../../driver/presentation/controllers/driver_prefetch.dart';
import '../../notifications/presentation/controllers/notifications_controller.dart';
import '../../picking/presentation/controllers/orders_worklist_controller.dart';
import '../../store/presentation/controllers/store_controllers.dart';
import '../../supervisor/presentation/controllers/supervisor_controllers.dart';

/// Precarga del inicio: al entrar, pide en segundo plano los datos de la
/// primera pantalla de cada rol para que el primer toque abra sin spinner.
///
/// No muestra nada ni espera nada: si falla, la pantalla lo vuelve a pedir al
/// abrirse como siempre. Lo precargado vive gracias a la caché corta
/// (`cacheFor`) de cada provider: la suscripción se cierra apenas llega el
/// dato y desde ahí corre su plazo.
class HomePrefetcher {
  const HomePrefetcher();

  /// Lanza la precarga del [role]. Se llama una vez al montar el inicio.
  void call(WidgetRef ref, UserRole role) {
    switch (role) {
      case UserRole.driver:
        // Tripulación + ruta del día (feature chofer). Sin la bandeja: en el
        // chofer la ruta es lo primero y no conviene competir por la red.
        prefetchDriverDay(ref);
        return;
      case UserRole.supervisor:
        // Si el inicio quedó abierto de un día para otro, que el tablero y los
        // planes precargados sean de hoy.
        ref.read(plansDateProvider.notifier).rollOverIfNewDay();
        prefetch(ref, dashboardMetricsProvider); // incluye los planes del día
        prefetch(ref, vehiclePlatesProvider); // sin "salto" UUID → placa
        prefetch(ref, alertsProvider);
      case UserRole.store:
        prefetch(ref, storeShipmentsProvider);
      case UserRole.picker:
        prefetch(ref, ordersToPrepareProvider);
      case UserRole.carrier:
        break;
    }
    // La campana abre al instante.
    prefetch(ref, notificationsListProvider);
  }
}

/// Precarga un provider asíncrono sin quedarse escuchándolo: lo arranca y
/// suelta la suscripción cuando termina (con dato o error). Así un provider con
/// `cacheFor` conserva el dato su plazo y después se libera normalmente; uno
/// sin caché simplemente se descarta.
void prefetch<T>(WidgetRef ref, ProviderListenable<AsyncValue<T>> provider) {
  ProviderSubscription<AsyncValue<T>>? sub;
  sub = ref.listenManual<AsyncValue<T>>(provider, (_, next) {
    if (!next.isLoading) sub?.close();
  });
  // Ya estaba resuelto (caché vigente): no hay cambio que esperar.
  if (!sub.read().isLoading) sub.close();
}

/// Precargador del inicio. Override en tests para no tocar la red.
final homePrefetcherProvider = Provider<HomePrefetcher>(
  (ref) => const HomePrefetcher(),
);
