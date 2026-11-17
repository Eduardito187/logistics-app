import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/performance/cache_for.dart';
import '../../../../core/push/push_arrived.dart';
import '../../../../core/widgets/paged.dart';

/// Bandeja de avisos internos del usuario (`/app/inbox`): lo que el
/// administrador le envió a su rol, a su tienda o a él. Cualquier rol la tiene.
class InboxRemoteDataSource {
  const InboxRemoteDataSource(this._ref);

  final Ref _ref;

  static const int pageSize = 30;

  LogisticsApi get _api => _ref.read(logisticsApiProvider);

  Future<Paged<StaffInboxItem>> list(int page) => _guard(() async {
    final res = await _api.staff.listInbox(page: page, perPage: pageSize);
    return Paged(
      items: res.data,
      hasMore: res.meta.nextPage != null || (res.meta.hasMore ?? false),
    );
  });

  /// Cuántos avisos sin leer tiene el usuario (hasta una página).
  Future<int> unreadCount() => _guard(() async {
    final res = await _api.staff.listInbox(
      page: 1,
      perPage: pageSize,
      unread: true,
    );
    // `meta.unread` = avisos sin leer + pendientes operativos.
    return res.meta.unread ?? res.meta.total ?? res.data.length;
  });

  Future<void> markRead(String broadcastId) => _guard(() async {
    await _api.staff.markInboxRead(broadcastId: broadcastId);
  });

  Future<void> markAllRead() => _guard(() async {
    await _api.staff.markInboxAllRead();
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final inboxRemoteDataSourceProvider = Provider<InboxRemoteDataSource>(
  InboxRemoteDataSource.new,
);

/// Avisos sin leer, para el acceso de la pantalla de notificaciones. Si falla
/// (sin señal, backend anterior) vale 0: la bandeja igual se puede abrir.
final inboxUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.cacheFor(CacheTtl.short);
  ref.watch(sessionProvider.select((s) => (s?.token != null, s?.userName)));
  ref.watch(pushArrivedProvider);
  try {
    return await ref.watch(inboxRemoteDataSourceProvider).unreadCount();
  } on Object {
    return 0;
  }
});

/// Los avisos más recientes del usuario (primera página), para mostrarlos
/// dentro de la pantalla de notificaciones. Si falla vale vacío: las
/// notificaciones de la operación igual se ven.
final inboxPreviewProvider = FutureProvider.autoDispose<Paged<StaffInboxItem>>((
  ref,
) async {
  // Caché corta atada a la sesión: al volver a la pantalla los avisos están
  // al instante (sin el hueco en blanco mientras cargan), y un push o un
  // aviso de tiempo real los vuelve a pedir igual.
  ref.cacheFor(CacheTtl.short);
  ref.watch(sessionProvider.select((s) => (s?.token != null, s?.userName)));
  ref.watch(pushArrivedProvider);
  try {
    return await ref.watch(inboxRemoteDataSourceProvider).list(1);
  } on Object {
    return const Paged(items: [], hasMore: false);
  }
});
