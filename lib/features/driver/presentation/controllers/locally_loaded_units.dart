import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';

/// Bultos que el chofer escaneó para CARGAR en este teléfono durante la sesión,
/// por envío (`shipmentId` → `unitId`s). Sin señal esos escaneos quedan en la
/// cola offline y el backend todavía no los cuenta; con esto la pantalla de
/// Carga muestra el conteo real apenas se vuelve de escanear.
///
/// Acotado: a lo sumo [maxShipments] envíos (se descartan los más viejos).
class LocallyLoadedUnits extends Notifier<Map<String, Set<String>>> {
  static const int maxShipments = 100;

  @override
  Map<String, Set<String>> build() => const {};

  void add(String shipmentId, String unitId) {
    final units = state[shipmentId];
    if (units != null && units.contains(unitId)) return;
    final next = <String, Set<String>>{
      for (final e in state.entries)
        if (e.key != shipmentId) e.key: e.value,
      shipmentId: Set.unmodifiable({...?units, unitId}),
    };
    while (next.length > maxShipments) {
      next.remove(next.keys.first);
    }
    state = Map.unmodifiable(next);
  }
}

final locallyLoadedUnitsProvider =
    NotifierProvider<LocallyLoadedUnits, Map<String, Set<String>>>(
      LocallyLoadedUnits.new,
    );

/// Escaneos a mostrar de [delivery]: los que ya trae el backend más los bultos
/// cargados en este teléfono que el backend todavía no tiene (sin duplicar:
/// cuando el escaneo se sincroniza, ese bulto ya viene en `scans`).
int effectiveScanCount(Delivery delivery, Set<String>? localUnits) {
  if (localUnits == null || localUnits.isEmpty) return delivery.scans.length;
  final known = {for (final s in delivery.scans) s.unitId};
  return delivery.scans.length +
      localUnits.where((u) => !known.contains(u)).length;
}
