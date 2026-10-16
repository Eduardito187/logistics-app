import '../../../../core/api/models/notification_view.dart';

/// Contrato de la bandeja de notificaciones de la operación. La capa `data` lo
/// implementa; la capa `presentation` sólo lo conoce a través de los casos de
/// uso. Lanza `ApiException` ante un error.
abstract interface class NotificationsRepository {
  /// Lista global de notificaciones (más recientes primero, según el backend).
  Future<List<NotificationView>> list();

  /// Detalle de una notificación por id.
  Future<NotificationView> get(String id);

  /// Suprime una notificación que aún está en cola.
  Future<void> suppress(String id);
}
