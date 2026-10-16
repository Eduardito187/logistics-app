import 'package:logistics_app/core/api/models/notification_view.dart';
import 'package:logistics_app/features/notifications/domain/repositories/notifications_repository.dart';

/// Repositorio falso de notificaciones para tests: valores en memoria y, si el
/// `*Error` correspondiente está seteado, lanza (para probar el estado de error).
/// Registra las supresiones para las aserciones.
class FakeNotificationsRepository implements NotificationsRepository {
  List<NotificationView> items = const [];
  Object? listError;

  NotificationView? detail;
  Object? detailError;

  final List<String> suppressedIds = [];
  Object? suppressError;

  @override
  Future<List<NotificationView>> list() async {
    if (listError != null) throw listError!;
    return items;
  }

  @override
  Future<NotificationView> get(String id) async {
    if (detailError != null) throw detailError!;
    return detail!;
  }

  @override
  Future<void> suppress(String id) async {
    if (suppressError != null) throw suppressError!;
    suppressedIds.add(id);
  }
}
