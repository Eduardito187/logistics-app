import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/catalog/failure_reason_option.dart';
import 'package:logistics_app/core/catalog/failure_reasons_repository.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/network/dio_client.dart';

/// Dio que responde [body] con [status] a cualquier GET (sin red real).
Dio _dioRespond(Object? body, {int status = 200}) => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: status,
          data: body,
        ),
      ),
    ),
  );

/// Dio que falla con [status] (p. ej. 404 = endpoint aún no desplegado).
Dio _dioFail(int status) => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: status,
          ),
        ),
      ),
    ),
  );

FailureReasonsRepository _repo(Dio dio) {
  final container = ProviderContainer(
    overrides: [dioProvider.overrideWithValue(dio)],
  );
  addTearDown(container.dispose);
  return container.read(failureReasonsRepositoryProvider);
}

void main() {
  test('listActive parsea, filtra los ocultos y ordena', () async {
    final repo = _repo(
      _dioRespond({
        'data': [
          {'code': 'A', 'label': 'Alfa', 'active': true, 'sort_order': 1},
          {'code': 'B', 'label': 'Beta', 'active': false, 'sort_order': 0},
          {'code': 'C', 'label': 'Charlie', 'active': true, 'sort_order': 0},
        ],
      }),
    );

    final active = await repo.listActive();

    expect(active.map((e) => e.code).toList(), [
      'C',
      'A',
    ]); // B oculto; por orden
  });

  test('listActive cae a los de fábrica si no hay endpoint/red', () async {
    final repo = _repo(_dioFail(404));

    final active = await repo.listActive();

    expect(active, isNotEmpty);
    expect(active.map((e) => e.code), contains('CUSTOMER_ABSENT'));
    expect(active.length, kDefaultFailureReasons.where((r) => r.active).length);
  });

  test(
    'listAll cae a los de fábrica si el backend aún no lo tiene (404)',
    () async {
      final repo = _repo(_dioFail(404));

      final all = await repo.listAll();

      expect(all.length, kDefaultFailureReasons.length);
    },
  );

  test('listAll propaga un error real (500) como ApiException', () async {
    final repo = _repo(_dioFail(500));

    await expectLater(repo.listAll(), throwsA(isA<ApiException>()));
  });

  test('lee requires_photo/requires_note/note_label del backend', () async {
    final repo = _repo(
      _dioRespond({
        'data': [
          {
            'code': 'ZONA',
            'label': 'Zona insegura',
            'active': true,
            'requires_photo': true,
            'requires_note': true,
            'note_label': '¿Qué pasó?',
            'sort_order': 0,
          },
        ],
      }),
    );

    final option = (await repo.listActive()).single;

    expect(option.requiresPhoto, isTrue);
    expect(option.requiresNote, isTrue);
    expect(option.noteFieldLabel, '¿Qué pasó?');
  });
}
