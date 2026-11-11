import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/logistics_api.dart';
import '../auth/session.dart';
import '../config/app_config.dart';
import 'app_version_interceptor.dart';
import 'auth_headers.dart';
import 'date_query_interceptor.dart';

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
      // Solo desloguear si el 401 corresponde al TOKEN DE LA SESIÓN ACTUAL. Un
      // request SIN token, o con un token VIEJO, que quedó en vuelo desde el
      // arranque o la pantalla de login y cuyo 401 llega DESPUÉS de un login
      // nuevo, NO debe tumbar la sesión recién abierta (era el bug intermitente
      // "me logueé y al instante dijo que la sesión expiró"). También protege
      // el desalojo de sesión por otro dispositivo: el 401 del token viejo no
      // afecta a una sesión distinta y vigente.
      if (_isCurrentSessionToken(err.requestOptions)) {
        // `handleUnauthorized` es idempotente: si ya no hay sesión, no hace
        // nada, así varios 401 en paralelo no reinician el cierre ni el aviso.
        // El aviso depende del motivo que informa el backend (código RFC7807):
        // desalojo por otro dispositivo, baja del dispositivo, o expiración.
        _ref
            .read(sessionProvider.notifier)
            .handleUnauthorized(
              reason: _unauthorizedReason(_errorCode(err.response?.data)),
            );
      }
    }
    handler.next(err);
  }

  /// Código de problema (RFC7807) del body del error, o `null`.
  String? _errorCode(Object? data) {
    if (data is Map) {
      final code = data['code'];
      if (code is String) return code;
    }
    return null;
  }

  /// Aviso para el usuario según el [code] del 401. `null` = usar el genérico de
  /// expiración (token vencido/ausente, `unauthenticated`).
  String? _unauthorizedReason(String? code) {
    switch (code) {
      case 'session_superseded':
        return 'Iniciaste sesión en otro dispositivo.';
      case 'device_revoked':
        return 'Este dispositivo fue dado de baja. Volvé a ingresar.';
      default:
        return null;
    }
  }

  /// `true` si el request que recibió el 401 se envió con el Bearer de la
  /// sesión ACTUAL. Un request sin `Authorization`, o con un token distinto del
  /// vigente (viejo o de otra sesión), devuelve `false`: su 401 no debe cerrar
  /// la sesión actual.
  bool _isCurrentSessionToken(RequestOptions options) {
    final sent = options.headers['Authorization'];
    if (sent is! String || !sent.startsWith('Bearer ')) return false;
    final sentToken = sent.substring('Bearer '.length);
    if (sentToken.isEmpty) return false;
    final current = _ref.read(authHeadersProvider).bearerToken;
    return current != null && current.isNotEmpty && sentToken == current;
  }

  /// Rutas de autenticación cuyo 401 NO debe disparar el logout global.
  ///
  /// - `/login` y `/token`: su 401 es "credenciales inválidas", no sesión caída.
  /// - `/auth/me`: se pide SOLO justo después del login (para las abilities) y es
  ///   "degradación segura" (si falla, la sesión queda sin abilities, no se
  ///   cierra). Sin esta excepción, un 401 de `/me` recién logueado sacaba al
  ///   usuario al login con "tu sesión expiró" (bug reportado).
  bool _isAuthEndpoint(String path) =>
      path.contains('/login') ||
      path.contains('/token') ||
      path.contains('/auth/me');
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

  // Conexiones TLS reusadas: el `idleTimeout` por defecto (15 s) cerraba el
  // socket entre escaneos y el próximo request pagaba TCP+TLS de nuevo.
  dio.httpClientAdapter = createApiHttpClientAdapter();

  dio.interceptors.add(_AuthInterceptor(ref));
  // Fechas de calendario del query como `Y-m-d` (el cliente generado manda ISO).
  dio.interceptors.add(const DateQueryInterceptor());
  // X-App-Version/X-App-Build en cada request + bloqueo por versión mínima.
  dio.interceptors.add(AppVersionInterceptor(ref));

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        logPrint: (o) => debugPrint(truncateLogLine('$o')),
      ),
    );
  }

  return dio;
});

/// Tiempo que una conexión ociosa al API queda abierta para reusarse.
const Duration kApiIdleTimeout = Duration(seconds: 90);

/// Conexiones simultáneas por host al API (GPS + escaneos + pantallas).
const int kApiMaxConnectionsPerHost = 6;

/// Adaptador HTTP del API: mantiene vivas las conexiones [kApiIdleTimeout] y
/// limita a [kApiMaxConnectionsPerHost] por host.
@visibleForTesting
IOHttpClientAdapter createApiHttpClientAdapter() => IOHttpClientAdapter(
  createHttpClient: () => HttpClient()
    ..idleTimeout = kApiIdleTimeout
    ..maxConnectionsPerHost = kApiMaxConnectionsPerHost,
);

/// Largo máximo de una línea del log HTTP (solo debug).
const int kHttpLogMaxChars = 600;

/// Recorta una línea del log HTTP: un body grande (lote de escaneos, ruta con
/// muchas paradas) no se imprime entero ni se copia en memoria al log.
@visibleForTesting
String truncateLogLine(String line, {int max = kHttpLogMaxChars}) {
  if (line.length <= max) return line;
  return '${line.substring(0, max)}… (+${line.length - max} caracteres)';
}

/// Cliente generado del API, con la raíz de la puerta `/app/*` ya resuelta por baseUrl.
final logisticsApiProvider = Provider<LogisticsApi>(
  (ref) => LogisticsApi(ref.watch(dioProvider)),
);
