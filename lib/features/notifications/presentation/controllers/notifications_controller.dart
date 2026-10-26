import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/get_notification.dart';
import '../../domain/usecases/list_notifications.dart';

/// Cuántas notificaciones se piden por "página". El endpoint solo acepta
/// `limit` (sin cursor): se arranca con las 30 más recientes y "Ver más" pide
/// 30 más. El backend por defecto mandaba 100 aunque casi nunca se miren.
const int notificationsPageSize = 30;

/// Tope de notificaciones en memoria (el backend acepta hasta 500). En un
/// teléfono de 1 GB no vale la pena retener más: las viejas se ven en la web.
const int notificationsMaxLimit = 150;

/// Cuántas notificaciones mostrar. Arranca en [notificationsPageSize] y crece
/// de a una página con [showMore], hasta [notificationsMaxLimit]. autoDispose:
/// vive mientras viva la lista (que lo escucha y tiene caché corta); pasado ese
/// plazo vuelve a la primera página.
class NotificationsLimitNotifier extends Notifier<int> {
  @override
  int build() => notificationsPageSize;

  /// `true` si todavía se puede pedir otra página.
  bool get canShowMore => state < notificationsMaxLimit;

  void showMore() {
    if (!canShowMore) return;
    final next = state + notificationsPageSize;
    state = next > notificationsMaxLimit ? notificationsMaxLimit : next;
  }
}

final notificationsLimitProvider =
    NotifierProvider.autoDispose<NotificationsLimitNotifier, int>(
      NotificationsLimitNotifier.new,
    );

/// Lista global de notificaciones (más recientes primero, según el backend),
/// acotada a [notificationsLimitProvider]. Lee a través del caso de uso
/// [ListNotifications].
///
/// Caché corta: abrir la campana dos veces seguidas (o ir al detalle y volver)
/// no repite el GET ni muestra spinner. El inicio la precarga.
final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationView>>((ref) async {
      ref.cacheFor(CacheTtl.short);
      // Otra sesión (cerrar y entrar con otro usuario) descarta la caché.
      ref.watch(sessionProvider.select((s) => (s?.token, s?.userName)));
      final limit = ref.watch(notificationsLimitProvider);
      final items = await ref
          .watch(listNotificationsProvider)
          .call(limit: limit);
      // Defensa: si el backend ignorara el `limit`, igual no se retienen más.
      return items.length <= limit
          ? items
          : List.unmodifiable(items.take(limit));
    });

/// Detalle de una notificación por id, vía el caso de uso [GetNotification].
///
/// Si la lista (cacheada) ya trae la notificación, se usa esa y no se pide
/// `GET /notifications/{id}`: la lista ya tiene el `NotificationView` completo.
/// Solo se pide por id al llegar directo (p. ej. desde un push) o tras
/// invalidar el detalle (suprimir).
final notificationDetailProvider = FutureProvider.autoDispose
    .family<NotificationView, String>((ref, id) {
      final listed = _findListed(ref, id);
      if (listed != null) return listed;
      return ref.watch(getNotificationProvider).call(id);
    });

/// La notificación [id] si la lista ya está cargada (sin disparar el GET de la
/// lista si no lo está: `exists` evita crearla solo para mirar). Si la lista se
/// está recargando (p. ej. tras suprimir) su dato es viejo: se pide por id.
NotificationView? _findListed(Ref ref, String id) {
  if (!ref.exists(notificationsListProvider)) return null;
  final list = ref.read(notificationsListProvider);
  if (list.isLoading) return null;
  final items = list.value;
  if (items == null) return null;
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}
