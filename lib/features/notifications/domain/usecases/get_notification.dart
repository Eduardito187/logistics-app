import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../repositories/notifications_repository.dart';

/// Caso de uso (Query, CQRS): obtiene el detalle de una notificación por id.
/// Delega en el repositorio; propaga `ApiException` ante un error.
class GetNotification {
  const GetNotification(this._repo);

  final NotificationsRepository _repo;

  Future<NotificationView> call(String id) => _repo.get(id);
}

final getNotificationProvider = Provider<GetNotification>(
  (ref) => GetNotification(ref.watch(notificationsRepositoryProvider)),
);
