import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../domain/usecases/get_notification.dart';
import '../../domain/usecases/list_notifications.dart';

/// Lista global de notificaciones (más recientes primero, según el backend).
/// Lee a través del caso de uso [ListNotifications].
final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationView>>((ref) {
      return ref.watch(listNotificationsProvider).call();
    });

/// Detalle de una notificación por id, vía el caso de uso [GetNotification].
final notificationDetailProvider = FutureProvider.autoDispose
    .family<NotificationView, String>((ref, id) {
      return ref.watch(getNotificationProvider).call(id);
    });
