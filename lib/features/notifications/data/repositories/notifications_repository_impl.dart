import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

/// Implementación del contrato de notificaciones. Delega cada operación en el
/// data source remoto; no agrega comportamiento propio.
class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<List<NotificationView>> list() => _remote.listNotifications();

  @override
  Future<NotificationView> get(String id) => _remote.getNotification(id);

  @override
  Future<void> suppress(String id) => _remote.suppressNotification(id);
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
  ),
);
