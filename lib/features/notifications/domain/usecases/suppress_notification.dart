import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository_impl.dart';
import '../repositories/notifications_repository.dart';

/// Caso de uso (Command, CQRS): suprime una notificación que está en cola.
/// Delega en el repositorio; propaga `ApiException` ante un error.
class SuppressNotification {
  const SuppressNotification(this._repo);

  final NotificationsRepository _repo;

  Future<void> call(String id) => _repo.suppress(id);
}

final suppressNotificationProvider = Provider<SuppressNotification>(
  (ref) => SuppressNotification(ref.watch(notificationsRepositoryProvider)),
);
