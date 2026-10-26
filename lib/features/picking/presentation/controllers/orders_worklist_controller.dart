import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/list_orders_to_prepare.dart';

/// Worklist del preparador/andén: pedidos pendientes de preparar y cargar.
/// Lectura simple (CQRS Query) expuesta como `FutureProvider`; la pantalla la
/// consume con `AsyncValueView` y la refresca con pull-to-refresh. Depende sólo
/// del caso de uso (nunca del cliente de la API directamente).
///
/// Caché corta: volver del pedido a la lista la muestra al instante, sin otro
/// GET; al refrescar, la lista previa sigue visible.
final ordersToPrepareProvider = FutureProvider.autoDispose<List<Shipment>>((
  ref,
) {
  ref.cacheFor(CacheTtl.short);
  return ref.watch(listOrdersToPrepareProvider).call();
});
