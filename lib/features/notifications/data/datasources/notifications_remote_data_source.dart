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

  /// GET `/app/notifications/all` (`appListNotifications`): lista global de la
  /// operación con alcance por rol, las [limit] más recientes (`null` = default
  /// del backend). NO es `/app/notifications` (ese es por envío y exige
  /// `shipment_id`, da 422 sin él).
  Future<List<NotificationView>> listNotifications({int? limit}) async {
    try {
      final api = _ref.read(logisticsApiProvider);
      final response = limit == null
          ? await api.notifications.appListNotifications()
          : await api.notifications.appListNotifications(perPage: limit);
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
