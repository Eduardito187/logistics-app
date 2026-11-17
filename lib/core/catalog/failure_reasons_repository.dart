import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../network/dio_client.dart';
import 'failure_reason_option.dart';

/// Catálogo de motivos de "no se pudo entregar".
///
/// Lectura para el chofer ([listActive]) y administración para el admin
/// ([listAll], [create], [update], [delete]). Va por **Dio directo**: el
/// contrato todavía no está en el cliente generado (se deriva al backend). Si el
/// backend aún no lo expone (404/405) o no hay red, cae a [kDefaultFailureReasons]
/// para que el flujo del chofer nunca quede sin motivos (offline-first).
///
/// Rutas del contrato propuesto:
///   GET    /app/config/failure-reasons          → activos, para el chofer
///   GET    /app/admin/failure-reasons           → todos, para el admin
///   POST   /app/admin/failure-reasons           → crear
///   PUT    /app/admin/failure-reasons/{code}    → editar (incl. activar/ocultar)
///   DELETE /app/admin/failure-reasons/{code}    → borrar
class FailureReasonsRepository {
  const FailureReasonsRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  static int _byOrder(FailureReasonOption a, FailureReasonOption b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    return c != 0 ? c : a.label.toLowerCase().compareTo(b.label.toLowerCase());
  }

  List<FailureReasonOption> _parse(Object? data) {
    final raw = data is Map ? data['data'] : null;
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, Object?>) FailureReasonOption.fromJson(item),
    ];
  }

  /// Motivos ACTIVOS para el chofer, ya ordenados. Respaldo: los de fábrica.
  Future<List<FailureReasonOption>> listActive() async {
    try {
      final res = await _dio.get<Map<String, Object?>>(
        '/app/config/failure-reasons',
      );
      final active = _parse(
        res.data,
      ).where((r) => r.active && r.code.isNotEmpty).toList()..sort(_byOrder);
      return active.isEmpty ? _defaultsActive() : active;
    } on DioException {
      // Sin red o sin endpoint: el chofer igual tiene con qué registrar.
      return _defaultsActive();
    }
  }

  /// TODOS los motivos para el admin, ordenados. Si el backend aún no tiene el
  /// endpoint (404/405), arranca con los de fábrica para poder configurarlos.
  Future<List<FailureReasonOption>> listAll() async {
    try {
      final res = await _dio.get<Map<String, Object?>>(
        '/app/admin/failure-reasons',
      );
      final all = _parse(res.data).toList()..sort(_byOrder);
      return all.isEmpty ? _defaultsAll() : all;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) return _defaultsAll();
      throw ApiException.fromDio(e);
    }
  }

  /// Crea un motivo nuevo.
  Future<void> create(FailureReasonOption option) => _guard(() async {
    await _dio.post<Object?>(
      '/app/admin/failure-reasons',
      data: option.toJson(),
    );
  });

  /// Edita un motivo (incluye activar/ocultar y las exigencias de foto/texto).
  /// Ocultar un motivo = `active: false` por esta vía (el backend trata el
  /// DELETE como baja lógica, equivalente a esto; no hay borrado físico porque
  /// las fallidas históricas guardan el `code`).
  Future<void> update(FailureReasonOption option) => _guard(() async {
    await _dio.put<Object?>(
      '/app/admin/failure-reasons/${Uri.encodeComponent(option.code)}',
      data: option.toJson(),
    );
  });

  List<FailureReasonOption> _defaultsActive() =>
      kDefaultFailureReasons.where((r) => r.active).toList()..sort(_byOrder);

  List<FailureReasonOption> _defaultsAll() =>
      List<FailureReasonOption>.of(kDefaultFailureReasons)..sort(_byOrder);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final failureReasonsRepositoryProvider = Provider<FailureReasonsRepository>(
  FailureReasonsRepository.new,
);

/// Motivos ACTIVOS para el chofer (pantalla de entrega fallida).
final activeFailureReasonsProvider = FutureProvider<List<FailureReasonOption>>(
  (ref) => ref.read(failureReasonsRepositoryProvider).listActive(),
);

/// TODOS los motivos para la pantalla de administración (se recarga con
/// `ref.invalidate` tras cada cambio).
final adminFailureReasonsProvider =
    FutureProvider.autoDispose<List<FailureReasonOption>>(
      (ref) => ref.read(failureReasonsRepositoryProvider).listAll(),
    );
