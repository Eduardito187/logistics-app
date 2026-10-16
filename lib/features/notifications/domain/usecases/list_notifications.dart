import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../repositories/notifications_repository.dart';

/// Caso de uso (Query, CQRS): lista las notificaciones de la operación.
/// Delega en el repositorio; propaga `ApiException` ante un error.
class ListNotifications {
  const ListNotifications(this._repo);

  final NotificationsRepository _repo;

  Future<List<NotificationView>> call() => _repo.list();
}

final listNotificationsProvider = Provider<ListNotifications>(
  (ref) => ListNotifications(ref.watch(notificationsRepositoryProvider)),
);
