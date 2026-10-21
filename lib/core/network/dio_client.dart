import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/logistics_api.dart';
import '../auth/session.dart';
import '../config/app_config.dart';
import 'app_version_interceptor.dart';
import 'auth_headers.dart';

/// Interceptor que agrega el Bearer por usuario+dispositivo y el `X-Device-Id`
/// a cada request de la puerta `/app/*`, leyendo las cabeceras vigentes en
/// memoria. Además maneja el 401 global: un token expirado o revocado cierra
/// la sesión y la UI vuelve al login vía `sessionProvider`.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = _ref.read(authHeadersProvider);
    final token = headers.bearerToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final deviceId = headers.deviceId;
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers['X-Device-Id'] = deviceId;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Ante un 401 cerramos sesión de forma global, salvo en el propio flujo de
    // login: su 401 es "credenciales inválidas", no una sesión caída, y forzar
    // logout ahí no aporta y podría enmascarar el error al usuario.
    //
    // Solo el 401 desloguea. Un 403 ("sin permiso") NO cierra sesión: el token
    // sigue siendo válido, simplemente esa acción no le corresponde al usuario.
    // Se propaga como DioException → ApiException (isForbidden) para que la
    // pantalla muestre "No tenés permiso" sin sacar al usuario. Ningún otro
    // código fuerza logout.
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 && !_isAuthEndpoint(err.requestOptions.path)) {
      // `handleUnauthorized` es idempotente: si ya no hay sesión, no hace nada,
      // así varios 401 en paralelo no reinician el cierre ni el aviso.
      _ref.read(sessionProvider.notifier).handleUnauthorized();
    }
    handler.next(err);
  }

  /// Rutas de autenticación cuyo 401 no debe disparar el logout global.
  bool _isAuthEndpoint(String path) =>
      path.contains('/login') || path.contains('/token');
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor(ref));
  // X-App-Version/X-App-Build en cada request + bloqueo por versión mínima.
  dio.interceptors.add(AppVersionInterceptor(ref));

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        logPrint: (o) => debugPrint('$o'),
      ),
    );
  }

  return dio;
});

/// Cliente generado del API, con la raíz de la puerta `/app/*` ya resuelta por baseUrl.
final logisticsApiProvider = Provider<LogisticsApi>(
  (ref) => LogisticsApi(ref.watch(dioProvider)),
);
