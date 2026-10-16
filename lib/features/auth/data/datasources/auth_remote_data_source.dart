import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature auth que toca el cliente de la API (`api.auth.*`).
/// Espeja el endpoint `/app/auth/login` y normaliza el error de Dio a
/// [ApiException] (el *Failure* del dominio del cliente).
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._ref);

  final Ref _ref;

  /// POST `/app/auth/login`. La respuesta es el propio [AppLoginResponse]
  /// (el body directo; no viene envuelto en un sobre `.data`).
  Future<AppLoginResponse> login(AppLoginRequest request) async {
    final api = _ref.read(logisticsApiProvider);
    try {
      return await api.auth.appLogin(body: request);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET `/app/auth/me`. Devuelve el perfil, el dispositivo y las `abilities`
  /// del token vigente. Requiere el Bearer ya puesto en las cabeceras.
  Future<AppMeResponse> me() async {
    final api = _ref.read(logisticsApiProvider);
    try {
      return await api.auth.appMe();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  AuthRemoteDataSource.new,
);
