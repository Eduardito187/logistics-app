import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/carrier.dart';
import '../../../../core/api/models/settlement.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/get_settlement.dart';
import '../../domain/usecases/list_carriers.dart';
import '../../domain/usecases/list_settlements.dart';

/// Controllers (providers) de lectura del transportista. Dependen solo de casos
/// de uso; ninguna pantalla toca el cliente API ni el repositorio directamente.

/// Lista de transportistas activos para que el usuario elija el suyo.
/// Catálogo casi fijo: caché larga (volver a elegir no la vuelve a pedir).
final carriersListProvider = FutureProvider.autoDispose<List<Carrier>>((ref) {
  ref.cacheFor(CacheTtl.long);
  return ref.watch(listCarriersProvider)();
});

/// Transportista elegido en esta sesión. Se guarda en memoria y lo usan las
/// pantallas de liquidaciones y tarifas (necesitan el `carrierId`).
class SelectedCarrierNotifier extends Notifier<Carrier?> {
  @override
  Carrier? build() => null;

  void select(Carrier carrier) => state = carrier;

  void clear() => state = null;
}

final selectedCarrierProvider =
    NotifierProvider<SelectedCarrierNotifier, Carrier?>(
      SelectedCarrierNotifier.new,
    );

/// Liquidaciones del transportista indicado. Caché corta: ir al detalle y
/// volver muestra la lista al instante.
final carrierSettlementsProvider = FutureProvider.autoDispose
    .family<List<Settlement>, String>((ref, carrierId) {
      ref.cacheFor(CacheTtl.short);
      return ref.watch(listSettlementsProvider)(carrierId);
    });

/// Detalle de una liquidación. La pantalla muestra mientras tanto la de la
/// lista (`extra`), así que no hay spinner al abrir.
final carrierSettlementProvider = FutureProvider.autoDispose
    .family<Settlement, String>(
      (ref, settlementId) => ref.watch(getSettlementProvider)(settlementId),
    );
