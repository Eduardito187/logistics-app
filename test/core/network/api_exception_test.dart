import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/problem_code.dart';
import 'package:logistics_app/core/network/api_exception.dart';

// ApiException: getters de clasificación, mensaje en español por caso,
// y parseo RFC 7807 (application/problem+json) desde DioException.

DioException _withResponse({
  int? statusCode,
  Object? data,
  String path = '/app/foo',
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

DioException _noResponse(DioExceptionType type) {
  return DioException(
    requestOptions: RequestOptions(path: '/app/foo'),
    type: type,
    message: 'boom',
  );
}

void main() {
  group('getters de clasificación por status', () {
    test('401 -> isUnauthorized', () {
      const e = ApiException(status: 401, title: 't');
      expect(e.isUnauthorized, isTrue);
      expect(e.isForbidden, isFalse);
    });

    test('403 -> isForbidden', () {
      const e = ApiException(status: 403, title: 't');
      expect(e.isForbidden, isTrue);
    });

    test('404 -> isNotFound', () {
      const e = ApiException(status: 404, title: 't');
      expect(e.isNotFound, isTrue);
    });

    test('409 -> isConflict', () {
      const e = ApiException(status: 409, title: 't');
      expect(e.isConflict, isTrue);
    });

    test('422 -> isValidation', () {
      const e = ApiException(status: 422, title: 't');
      expect(e.isValidation, isTrue);
    });

    test('429 -> isRateLimited', () {
      const e = ApiException(status: 429, title: 't');
      expect(e.isRateLimited, isTrue);
    });

    test('500 y 503 -> isServerError; 499 no', () {
      expect(const ApiException(status: 500, title: 't').isServerError, isTrue);
      expect(const ApiException(status: 503, title: 't').isServerError, isTrue);
      expect(
        const ApiException(status: 499, title: 't').isServerError,
        isFalse,
      );
    });

    test('status 0 (sin red) no es server error', () {
      const e = ApiException(status: 0, title: 't', isConnectionError: true);
      expect(e.isServerError, isFalse);
      expect(e.isConnectionError, isTrue);
    });
  });

  group('getters de clasificación por ProblemCode (status no coincidente)', () {
    test('code conflict -> isConflict aunque el status no sea 409', () {
      const e = ApiException(
        status: 400,
        title: 't',
        code: ProblemCode.conflict,
      );
      expect(e.isConflict, isTrue);
    });

    test('code validation_failed -> isValidation', () {
      const e = ApiException(
        status: 400,
        title: 't',
        code: ProblemCode.validationFailed,
      );
      expect(e.isValidation, isTrue);
    });

    test('code not_found -> isNotFound', () {
      const e = ApiException(
        status: 400,
        title: 't',
        code: ProblemCode.notFound,
      );
      expect(e.isNotFound, isTrue);
    });

    test('code rate_limited -> isRateLimited', () {
      const e = ApiException(
        status: 400,
        title: 't',
        code: ProblemCode.rateLimited,
      );
      expect(e.isRateLimited, isTrue);
    });

    test(
      'isForbidden cubre forbidden, insufficient_role e insufficient_scope',
      () {
        for (final code in [
          ProblemCode.forbidden,
          ProblemCode.insufficientRole,
          ProblemCode.insufficientScope,
        ]) {
          final e = ApiException(status: 200, title: 't', code: code);
          expect(e.isForbidden, isTrue, reason: 'falló con $code');
        }
      },
    );

    test('un code no relacionado no activa los getters', () {
      const e = ApiException(
        status: 200,
        title: 't',
        code: ProblemCode.serverError,
      );
      expect(e.isForbidden, isFalse);
      expect(e.isConflict, isFalse);
      expect(e.isNotFound, isFalse);
      expect(e.isValidation, isFalse);
      expect(e.isRateLimited, isFalse);
    });
  });

  group('message (precedencia y textos en español)', () {
    test('sin conexión gana sobre todo lo demás', () {
      const e = ApiException(
        status: 0,
        title: 't',
        detail: 'ignorado',
        isConnectionError: true,
      );
      expect(
        e.message,
        'No se pudo completar. Intentá de nuevo en un momento.',
      );
    });

    test('forbidden: mensaje fijo, ignora el detail', () {
      const e = ApiException(status: 403, title: 't', detail: 'otro');
      expect(e.message, 'No tenés permiso para esta acción.');
    });

    test('rate limited: mensaje fijo, ignora el detail', () {
      const e = ApiException(status: 429, title: 't', detail: 'otro');
      expect(e.message, 'Demasiadas solicitudes, probá de nuevo.');
    });

    test('server error: mensaje fijo, ignora el detail', () {
      const e = ApiException(status: 500, title: 't', detail: 'stacktrace');
      expect(e.message, 'Error del servidor. Probá de nuevo en un momento.');
    });

    test('si hay detail (y no es caso fijo) se prefiere el detail', () {
      const e = ApiException(
        status: 400,
        title: 't',
        detail: 'Mensaje puntual',
      );
      expect(e.message, 'Mensaje puntual');
    });

    test('detail vacío no se usa: cae al texto por caso/estado', () {
      const e = ApiException(status: 404, title: 'titulo', detail: '');
      expect(e.message, 'No se encontró lo que buscabas.');
    });

    test('404 sin detail -> texto de no encontrado', () {
      const e = ApiException(status: 404, title: 't');
      expect(e.message, 'No se encontró lo que buscabas.');
    });

    test('409 sin detail -> texto de conflicto', () {
      const e = ApiException(status: 409, title: 't');
      expect(
        e.message,
        'Hay un conflicto con el estado actual. Actualizá y probá de nuevo.',
      );
    });

    test('422 sin detail -> texto de validación', () {
      const e = ApiException(status: 422, title: 't');
      expect(e.message, 'Revisá los datos ingresados.');
    });

    test('caso sin regla ni detail cae al title (p. ej. 401)', () {
      const e = ApiException(status: 401, title: 'Sesión no válida');
      expect(e.message, 'Sesión no válida');
    });
  });

  group('fromDio: sin respuesta (red/timeout)', () {
    test('connectionTimeout -> status 0, isConnectionError true', () {
      final e = ApiException.fromDio(
        _noResponse(DioExceptionType.connectionTimeout),
      );
      expect(e.status, 0);
      expect(e.title, 'Sin conexión');
      expect(e.detail, 'boom');
      expect(e.isConnectionError, isTrue);
    });

    test(
      'connectionError, sendTimeout y receiveTimeout -> isConnectionError true',
      () {
        for (final type in [
          DioExceptionType.connectionError,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
        ]) {
          expect(
            ApiException.fromDio(_noResponse(type)).isConnectionError,
            isTrue,
            reason: 'falló con $type',
          );
        }
      },
    );

    test('cancel (sin respuesta) -> status 0 pero isConnectionError false', () {
      final e = ApiException.fromDio(_noResponse(DioExceptionType.cancel));
      expect(e.status, 0);
      expect(e.isConnectionError, isFalse);
    });
  });

  group('fromDio: respuesta RFC 7807 bien formada', () {
    test('parsea title, detail, type y code', () {
      final e = ApiException.fromDio(
        _withResponse(
          statusCode: 403,
          data: {
            'type': 'https://errors/forbidden',
            'title': 'Sin permiso',
            'status': 403,
            'detail': 'No podés ver esto.',
            'code': 'forbidden',
          },
        ),
      );
      expect(e.status, 403);
      expect(e.title, 'Sin permiso');
      expect(e.detail, 'No podés ver esto.');
      expect(e.type, 'https://errors/forbidden');
      expect(e.code, ProblemCode.forbidden);
      expect(e.isForbidden, isTrue);
    });

    test('errores de validación 422: map de campo -> lista de mensajes', () {
      final e = ApiException.fromDio(
        _withResponse(
          statusCode: 422,
          data: {
            'title': 'Datos inválidos',
            'code': 'validation_failed',
            'errors': {
              'email': ['Requerido', 'Formato inválido'],
              'edad': 'Debe ser número', // valor no-lista -> lista de 1
            },
          },
        ),
      );
      expect(e.fieldErrors['email'], ['Requerido', 'Formato inválido']);
      expect(e.fieldErrors['edad'], ['Debe ser número']);
      expect(e.isValidation, isTrue);
    });

    test('errors con valor null para un campo: se omite', () {
      final e = ApiException.fromDio(
        _withResponse(
          statusCode: 422,
          data: {
            'errors': {
              'campo_ok': ['x'],
              'campo_null': null,
            },
          },
        ),
      );
      expect(e.fieldErrors.containsKey('campo_null'), isFalse);
      expect(e.fieldErrors['campo_ok'], ['x']);
    });

    test('code desconocido -> ProblemCode.\$unknown (no null)', () {
      final e = ApiException.fromDio(
        _withResponse(
          statusCode: 400,
          data: {'code': 'un_codigo_que_no_existe'},
        ),
      );
      expect(e.code, ProblemCode.$unknown);
    });
  });

  group('fromDio: respuesta mal formada o parcial', () {
    test('body no-Map (string): title por estado, sin code ni detail', () {
      final e = ApiException.fromDio(
        _withResponse(statusCode: 500, data: 'Internal Server Error'),
      );
      expect(e.status, 500);
      expect(e.title, 'Error del servidor');
      expect(e.detail, isNull);
      expect(e.code, isNull);
      expect(e.fieldErrors, isEmpty);
    });

    test('body null -> fallback por estado', () {
      final e = ApiException.fromDio(
        _withResponse(statusCode: 404, data: null),
      );
      expect(e.title, 'No encontrado');
      expect(e.code, isNull);
    });

    test('code no-string (número) -> code null', () {
      final e = ApiException.fromDio(
        _withResponse(statusCode: 400, data: {'code': 123}),
      );
      expect(e.code, isNull);
    });

    test('errors no-Map -> fieldErrors vacío', () {
      final e = ApiException.fromDio(
        _withResponse(statusCode: 422, data: {'errors': 'oops'}),
      );
      expect(e.fieldErrors, isEmpty);
    });

    test(
      'sin title en el body: título por estado para cada status conocido',
      () {
        final cases = {
          401: 'Sesión no válida',
          403: 'Sin permiso',
          404: 'No encontrado',
          409: 'Conflicto',
          422: 'Datos inválidos',
          429: 'Demasiadas solicitudes',
        };
        cases.forEach((status, title) {
          final e = ApiException.fromDio(
            _withResponse(statusCode: status, data: const <String, Object?>{}),
          );
          expect(e.title, title, reason: 'status $status');
        });
      },
    );

    test('status desconocido (418) sin title -> "Error del servidor"', () {
      final e = ApiException.fromDio(
        _withResponse(statusCode: 418, data: const <String, Object?>{}),
      );
      expect(e.title, 'Error del servidor');
    });

    test(
      'statusCode null en la respuesta -> status 0 y título por defecto',
      () {
        final e = ApiException.fromDio(
          _withResponse(statusCode: null, data: const <String, Object?>{}),
        );
        expect(e.status, 0);
        expect(e.title, 'Error del servidor');
      },
    );
  });

  test('toString incluye status y title', () {
    const e = ApiException(status: 409, title: 'Conflicto');
    expect(e.toString(), 'ApiException(409, Conflicto)');
  });
}
