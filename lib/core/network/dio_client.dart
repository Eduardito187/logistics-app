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
import 'date_body_interceptor.dart';
import 'date_query_interceptor.dart';
import 'null_body_strip_interceptor.dart';

/// Interceptor que agrega el Bearer por usuario+dispositivo y el `X-Device-Id`
/// a cada request de la puerta `/app/*`, leyendo las cabeceras vigentes en
/// memoria. Además maneja el 401 global: un token expirado o revocado cierra
/// la sesión y la UI vuelve al login vía `sessionProvider`.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._ref, this._dio);

  final Ref _ref;

  /// El mismo Dio al que pertenece: para reintentar UNA vez un request tras el
  /// desfase del caché del backend (ver [_retryAfterFreshLogin]).
  final Dio _dio;

  /// Marca en `RequestOptions.extra` de un request ya reintentado (nunca dos).
  static const String _bindingRetryKey = 'deviceBindingRetried';

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
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
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
        final code = _errorCode(err.response?.data);
        // Login recién hecho + "dispositivo de otro usuario/desalojado": es el
        // desfase del caché del backend, no una baja real. Se reintenta.
        if (await _retryAfterFreshLogin(err, code, handler)) return;
        // Mientras se esperaba pudo cambiar la sesión: re-chequear el token.
        if (_isCurrentSessionToken(err.requestOptions)) {
          // `handleUnauthorized` es idempotente: si ya no hay sesión, no hace
          // nada, así varios 401 en paralelo no reinician el cierre ni el
          // aviso. El aviso depende del motivo que informa el backend (código
          // RFC7807): desalojo por otro dispositivo, baja, o expiración.
          _ref
              .read(sessionProvider.notifier)
              .handleUnauthorized(reason: _unauthorizedReason(code));
        }
      }
    }
    handler.next(err);
  }

  /// Defensa ante el bug "inicié sesión con OTRO usuario en el mismo teléfono y
  /// me sacó con 'dispositivo dado de baja'".
  ///
  /// El backend cachea ~30 s el estado del dispositivo (`user_id`, revocado) en
  /// su guarda de la puerta `/app/*`. Al loguear un usuario distinto en el
  /// mismo teléfono la fila del dispositivo pasa al usuario nuevo, pero si el
  /// caché todavía dice "usuario anterior" (o "desalojado"), responde 401
  /// `device_revoked` / `session_superseded` con el token RECIÉN emitido.
  ///
  /// Un token emitido hace segundos no puede estar dado de baja de verdad, así
  /// que dentro de [deviceBindingGraceProvider] desde el login se espera a que
  /// venza ese caché y se reintenta el request UNA vez. Si el reintento vuelve
  /// a dar 401, el interceptor lo trata normal (cierre con aviso). Devuelve
  /// `true` si se encargó del request (resuelto o error del reintento).
  Future<bool> _retryAfterFreshLogin(
    DioException err,
    String? code,
    ErrorInterceptorHandler handler,
  ) async {
    if (code != 'device_revoked' && code != 'session_superseded') return false;
    final options = err.requestOptions;
    if (options.extra[_bindingRetryKey] == true) return false;
    final signedInAt = _ref.read(sessionProvider.notifier).freshSignInAt;
    if (signedInAt == null) return false;
    final grace = _ref.read(deviceBindingGraceProvider);
    final elapsed = DateTime.now().difference(signedInAt);
    if (elapsed.isNegative || elapsed >= grace) return false;

    await Future<void>.delayed(grace - elapsed);
    // Si la sesión cambió o se cerró mientras esperábamos, no se reintenta.
    if (!_isCurrentSessionToken(options)) return false;

    options.extra[_bindingRetryKey] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      // El 401 del reintento ya pasó por este interceptor (sin nuevo reintento)
      // y cerró la sesión si correspondía; acá solo se propaga el error.
      handler.next(e);
    }
    return true;
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

/// Ventana tras un login real en la que un 401 `device_revoked` /
/// `session_superseded` se considera desfase del caché del backend (TTL 30 s
/// del snapshot del dispositivo) y se reintenta en vez de cerrar la sesión.
/// 30 s del backend + margen. Overridable en tests.
const Duration kDeviceBindingGrace = Duration(seconds: 35);

final deviceBindingGraceProvider = Provider<Duration>(
  (ref) => kDeviceBindingGrace,
);

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

  dio.interceptors.add(_AuthInterceptor(ref, dio));
  // Omite del cuerpo los campos opcionales en `null` (el cliente generado los
  // incluye siempre): varias validaciones del backend son `sometimes|string`
  // sin `nullable` y un `null` explícito da 422 (era la causa de "No se pudo
  // registrar" en el POD por `device_id`/`user_id`). Va ANTES de serializar.
  dio.interceptors.add(const NullBodyStripInterceptor());
  // Fechas de calendario del query como `Y-m-d` (el cliente generado manda ISO).
  dio.interceptors.add(const DateQueryInterceptor());
  // Idem para los campos de fecha-de-calendario del CUERPO (`plan_date`,
  // `performed_on`, …): el backend los valida `date_format:Y-m-d` y el cliente
  // generado manda fecha-hora ISO → 422. No toca los `*_at` (fecha-hora reales).
  dio.interceptors.add(const DateBodyInterceptor());
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
