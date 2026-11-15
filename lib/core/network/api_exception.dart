import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';

import '../api/models/problem_code.dart';

/// Error de API normalizado. El backend responde errores como RFC 7807
/// (`application/problem+json`): `{type, title, status, detail, code, errors}`,
/// y además repite el motivo en `error.message` y el código en `error.code`
/// (texto idéntico a `detail`/`code`). Los clientes deben ramificar por `code`
/// (estable), no por `title`. Leemos el anidado `error.*` como respaldo: cubre
/// el formato unificado nuevo, el viejo `{error:{code,message}}` y el
/// `error`/problem POR ÍTEM del 207 por lotes.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.title,
    this.detail,
    this.type,
    this.code,
    this.fieldErrors = const {},
    this.isConnectionError = false,
    this.retryAfter,
  });

  /// Código HTTP, o 0 si ni siquiera hubo respuesta (sin red).
  final int status;
  final String title;
  final String? detail;
  final String? type;

  /// Código legible por máquina del catálogo de errores (`ProblemCode`).
  /// `null` si la respuesta no trae `code` (p. ej. un error no-RFC7807 o sin red).
  final ProblemCode? code;

  /// Errores de validación por campo (422), `{campo: [mensajes]}`.
  final Map<String, List<String>> fieldErrors;

  /// `true` cuando la causa es falta de conexión/timeout, no un 4xx/5xx.
  /// En offline-first esto significa "reintentar luego", no "falló el dato".
  final bool isConnectionError;

  /// Espera que PIDE el servidor en la cabecera `Retry-After` (429 y 503).
  /// `null` si la respuesta no la trae o viene con un valor ilegible. Es un
  /// mínimo: la cola offline la combina con su propio backoff y toma el mayor
  /// (ver `SyncRetryPolicy.delayFor`).
  final Duration? retryAfter;

  bool get isValidation =>
      status == 422 || code == ProblemCode.validationFailed;
  bool get isUnauthorized => status == 401;
  bool get isConflict => status == 409 || code == ProblemCode.conflict;

  /// Sin permiso (403). Cubre el 403 "pelado" y los códigos de permiso del
  /// backend (`forbidden`, `insufficient_role`, `insufficient_scope`). NO
  /// desloguea: el usuario sigue adentro, solo que esta acción no le toca.
  bool get isForbidden =>
      status == 403 ||
      code == ProblemCode.forbidden ||
      code == ProblemCode.insufficientRole ||
      code == ProblemCode.insufficientScope;

  bool get isNotFound => status == 404 || code == ProblemCode.notFound;
  bool get isRateLimited => status == 429 || code == ProblemCode.rateLimited;
  bool get isServerError => status >= 500;

  /// Mensaje corto apto para un SnackBar en español. Mensajes fijos y claros
  /// para los casos sin dato útil (permiso, rate limit, servidor); para el
  /// resto preferimos el `detail` del backend y caemos a un texto por estado.
  String get message {
    if (isConnectionError) {
      // Offline invisible: no se revela la falta de señal al usuario.
      return 'No se pudo completar. Intentá de nuevo en un momento.';
    }
    if (isForbidden) {
      return 'No tenés permiso para esta acción.';
    }
    if (isRateLimited) {
      return 'Demasiadas solicitudes, probá de nuevo.';
    }
    if (isServerError) {
      return 'Error del servidor. Probá de nuevo en un momento.';
    }
    if (detail != null && detail!.isNotEmpty) {
      return detail!;
    }
    if (isNotFound) {
      return 'No se encontró lo que buscabas.';
    }
    if (isConflict) {
      return 'Hay un conflicto con el estado actual. Actualizá y probá de nuevo.';
    }
    if (isValidation) {
      // Mostrar el error de validación CONCRETO del backend (Laravel lo manda
      // en `errors`), no un genérico inútil: así se ve qué campo falla en vez
      // de "Revisá los datos ingresados." a secas.
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.values.first.first;
      }
      return 'Revisá los datos ingresados.';
    }
    return title;
  }

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    const connectionTypes = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    };
    if (response == null) {
      return ApiException(
        status: 0,
        title: 'Sin conexión',
        detail: e.message,
        isConnectionError: connectionTypes.contains(e.type),
      );
    }

    final data = response.data;
    final problem = data is Map
        ? data.cast<String, Object?>()
        : const <String, Object?>{};
    // `error` anidado (`{code, message}`): respaldo redundante del motivo y el
    // código cuando no vinieran en el nivel superior (shape viejo, o 207 por
    // ítem). El backend unificado manda ambos, idénticos; leemos el que haya.
    final rawNestedError = problem['error'];
    final nestedError = rawNestedError is Map
        ? rawNestedError.cast<String, Object?>()
        : const <String, Object?>{};
    final rawErrors = problem['errors'];
    final fieldErrors = <String, List<String>>{};
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          fieldErrors['$key'] = value.map((e) => '$e').toList();
        } else if (value != null) {
          fieldErrors['$key'] = ['$value'];
        }
      });
    }

    final rawCode = problem['code'] ?? nestedError['code'];
    final rawDetail = problem['detail'] ?? nestedError['message'];

    return ApiException(
      status: response.statusCode ?? 0,
      title:
          (problem['title'] as String?) ?? _titleForStatus(response.statusCode),
      detail: rawDetail is String ? rawDetail : null,
      type: problem['type'] as String?,
      code: rawCode is String ? ProblemCode.fromJson(rawCode) : null,
      fieldErrors: fieldErrors,
      retryAfter: parseRetryAfter(response.headers.value('retry-after')),
    );
  }

  /// Lee la cabecera `Retry-After` (RFC 9110): segundos ("120") o fecha HTTP
  /// ("Wed, 21 Oct 2026 07:28:00 GMT"). Devuelve `null` si viene vacía, no se
  /// entiende o ya pasó (una fecha en el pasado no justifica esperar).
  /// [now] existe para los tests; en producción es el reloj del teléfono.
  static Duration? parseRetryAfter(String? raw, {DateTime? now}) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) {
      // Un valor negativo o cero no es una espera: se ignora.
      return seconds > 0 ? Duration(seconds: seconds) : null;
    }
    try {
      final until = HttpDate.parse(value);
      final delta = until.difference(now ?? DateTime.now());
      return delta > Duration.zero ? delta : null;
    } on Object {
      // Cabecera ilegible (o reloj del teléfono desfasado): manda el backoff.
      return null;
    }
  }

  static String _titleForStatus(int? status) {
    switch (status) {
      case 401:
        return 'Sesión no válida';
      case 403:
        return 'Sin permiso';
      case 404:
        return 'No encontrado';
      case 409:
        return 'Conflicto';
      case 422:
        return 'Datos inválidos';
      case 429:
        return 'Demasiadas solicitudes';
      default:
        return 'Error del servidor';
    }
  }

  @override
  String toString() => 'ApiException($status, $title)';
}
