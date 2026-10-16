import 'package:dio/dio.dart';

import '../api/models/problem_code.dart';

/// Error de API normalizado. El backend responde errores como RFC 7807
/// (`application/problem+json`): `{type, title, status, detail, code, errors}`.
/// Los clientes deben ramificar por `code` (estable), no por `title`.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.title,
    this.detail,
    this.type,
    this.code,
    this.fieldErrors = const {},
    this.isConnectionError = false,
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
      return 'Sin conexión. Se guardó y se reintentará al recuperar señal.';
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

    final rawCode = problem['code'];

    return ApiException(
      status: response.statusCode ?? 0,
      title:
          (problem['title'] as String?) ?? _titleForStatus(response.statusCode),
      detail: problem['detail'] as String?,
      type: problem['type'] as String?,
      code: rawCode is String ? ProblemCode.fromJson(rawCode) : null,
      fieldErrors: fieldErrors,
    );
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
