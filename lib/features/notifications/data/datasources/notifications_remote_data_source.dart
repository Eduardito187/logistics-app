import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature notifications que toca el cliente de la API
/// (`api.notifications.*`). Cada método espeja un endpoint de la puerta
/// `/app/*`, devuelve el modelo generado desde `.data` y normaliza el error
/// de Dio a [ApiException] (el *Failure* del dominio del cliente).
class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._ref);

  final Ref _ref;

  /// GET `/app/notifications`. Lista global de notificaciones de la operación.
  Future<List<NotificationView>> listNotifications() async {
    try {
      final api = _ref.read(logisticsApiProvider);
      final response = await api.notifications.appListNotifications();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET `/app/notifications/{id}`. Detalle de una notificación por id.
  Future<NotificationView> getNotification(String id) async {
    try {
      final api = _ref.read(logisticsApiProvider);
      final response = await api.notifications.appGetNotification(
        notification: id,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/notifications/{id}/suppress`. Suprime una notificación en cola.
  Future<void> suppressNotification(String id) async {
    try {
      final api = _ref.read(logisticsApiProvider);
      await api.notifications.appSuppressNotification(notification: id);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(NotificationsRemoteDataSource.new);
