import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/app_me_response.dart';
import '../../../../core/api/models/device_list_item.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature settings que toca el cliente de la API
/// (`api.auth.*` y `api.settings.*`). Cada método espeja un endpoint de la
/// puerta `/app/*`, devuelve el modelo generado desde `.data` cuando aplica y
/// normaliza el error de Dio a [ApiException] (el *Failure* del dominio del
/// cliente).
class SettingsRemoteDataSource {
  const SettingsRemoteDataSource(this._ref);

  final Ref _ref;

  /// GET `/app/auth/me`. Perfil del usuario, dispositivo actual y habilidades.
  Future<AppMeResponse> getMe() async {
    try {
      final api = _ref.read(logisticsApiProvider);
      return await api.auth.appMe();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET `/app/devices`. Dispositivos/sesiones del usuario.
  Future<List<DeviceListItem>> listDevices() async {
    try {
      final api = _ref.read(logisticsApiProvider);
      final response = await api.auth.listDevices();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE `/app/devices/{uuid}`. Revoca la sesión de un dispositivo.
  Future<void> revokeDevice(String uuid) async {
    try {
      final api = _ref.read(logisticsApiProvider);
      await api.auth.revokeDevice(uuid: uuid);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>(
  SettingsRemoteDataSource.new,
);
