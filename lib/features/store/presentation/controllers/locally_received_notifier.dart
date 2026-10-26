import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bultos recibidos localmente en esta sesión (feedback inmediato offline-first),
/// indexados por envío. Se fusionan con lo que confirma el servidor para que el
/// conteo avance aunque el escaneo todavía no se haya sincronizado.
final locallyReceivedProvider =
    NotifierProvider<LocallyReceivedNotifier, Map<String, Set<String>>>(
      LocallyReceivedNotifier.new,
    );

/// Acumula los ids de bulto recibidos localmente por envío.
///
/// Acotado para un turno largo en un teléfono de 1 GB: se guardan a lo sumo
/// [maxShipments] envíos (se descarta el usado hace más tiempo) y el envío se
/// borra al conciliar su recepción ([clear]).
class LocallyReceivedNotifier extends Notifier<Map<String, Set<String>>> {
  /// Envíos con recepción en curso que se recuerdan a la vez.
  static const int maxShipments = 20;

  @override
  Map<String, Set<String>> build() => <String, Set<String>>{};

  void add(String shipmentId, String unitId) {
    final current = state[shipmentId];
    if (current != null && current.contains(unitId)) return;
    // El envío tocado va al final (orden de inserción = uso reciente).
    final next = {...state}..remove(shipmentId);
    next[shipmentId] = {...?current, unitId};
    while (next.length > maxShipments) {
      next.remove(next.keys.first);
    }
    state = next;
  }

  /// Deshace un bulto marcado de forma optimista (p. ej. el backend lo
  /// rechazó con un error de datos).
  void remove(String shipmentId, String unitId) {
    final current = state[shipmentId];
    if (current == null || !current.contains(unitId)) return;
    state = {
      ...state,
      shipmentId: {...current}..remove(unitId),
    };
  }

  /// Olvida lo recibido localmente de un envío (p. ej. al conciliar).
  void clear(String shipmentId) {
    if (!state.containsKey(shipmentId)) return;
    state = {...state}..remove(shipmentId);
  }

  Set<String> forShipment(String shipmentId) =>
      state[shipmentId] ?? const <String>{};
}
