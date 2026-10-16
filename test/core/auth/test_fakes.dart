// Dobles de prueba compartidos por los tests de `core/auth` y `core/network`.
//
// No se usa ninguna librería de mocking (no hay mocktail en el proyecto): los
// dobles implementan la interfaz real y resuelven lo no usado vía noSuchMethod.
// Nada de Dio real ni de almacenamiento seguro real.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logistics_app/core/api/clients/auth_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/api/models/app_token_response.dart';
import 'package:logistics_app/core/api/models/message_response.dart';

/// Almacén seguro en memoria. Enruta todo por noSuchMethod para no acoplarse a
/// la firma exacta (que cambia entre versiones de flutter_secure_storage).
class FakeSecureStorage implements FlutterSecureStorage {
  FakeSecureStorage({this.throwOnDelete = false});

  final Map<String, String> data = {};

  /// Si es true, `delete` lanza una excepción (simula fallo del almacén).
  bool throwOnDelete;

  /// Inyecta un valor crudo sin pasar por `write` (p. ej. un deviceId vacío).
  void seed(String key, String value) => data[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final member = invocation.memberName;
    final key = invocation.namedArguments[#key] as String?;
    if (member == #read) {
      return Future<String?>.value(key == null ? null : data[key]);
    }
    if (member == #write) {
      final value = invocation.namedArguments[#value] as String?;
      if (key != null) {
        if (value == null) {
          data.remove(key);
        } else {
          data[key] = value;
        }
      }
      return Future<void>.value();
    }
    if (member == #delete) {
      if (throwOnDelete) {
        throw Exception('fallo simulado del almacén seguro');
      }
      if (key != null) data.remove(key);
      return Future<void>.value();
    }
    if (member == #containsKey) {
      return Future<bool>.value(key != null && data.containsKey(key));
    }
    if (member == #deleteAll) {
      data.clear();
      return Future<void>.value();
    }
    if (member == #readAll) {
      return Future<Map<String, String>>.value(Map.of(data));
    }
    return super.noSuchMethod(invocation);
  }
}

/// Cliente de auth configurable. Solo se implementan `appRefresh`/`appLogout`
/// (lo que toca la sesión); el resto cae en noSuchMethod.
class FakeAuthClient implements AuthClient {
  /// Respuesta que devuelve `appRefresh` si no hay error configurado.
  AppTokenResponse refreshResponse = const AppTokenResponse(
    token: 'rotated-token',
    tokenType: 'Bearer',
    expiresAt: null,
  );

  /// Si está seteado, `appRefresh` lanza esto.
  Object? refreshError;

  /// Si está seteado, `appLogout` lanza esto.
  Object? logoutError;

  /// Retraso de `appLogout` (para ejercitar el `.timeout(...)` de signOut).
  Duration? logoutDelay;

  int refreshCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AppTokenResponse> appRefresh() async {
    refreshCalls++;
    final error = refreshError;
    if (error != null) throw error;
    return refreshResponse;
  }

  @override
  Future<MessageResponse> appLogout() async {
    logoutCalls++;
    final delay = logoutDelay;
    if (delay != null) await Future<void>.delayed(delay);
    final error = logoutError;
    if (error != null) throw error;
    return const MessageResponse(message: 'ok');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// API generada falsa: solo expone el cliente `auth`; el resto cae en
/// noSuchMethod (los tests de sesión no tocan otros módulos).
class FakeLogisticsApi implements LogisticsApi {
  FakeLogisticsApi(this._auth);

  final FakeAuthClient _auth;

  @override
  AuthClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// DioException de respuesta con un cuerpo RFC 7807 arbitrario.
DioException dioResponseError({
  required int statusCode,
  Map<String, Object?>? body,
  String path = '/app/auth/refresh',
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
  );
}
