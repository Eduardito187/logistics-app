import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bultos recibidos localmente en esta sesión (feedback inmediato offline-first),
/// indexados por envío. Se fusionan con lo que confirma el servidor para que el
/// conteo avance aunque el escaneo todavía no se haya sincronizado.
final locallyReceivedProvider =
    NotifierProvider<LocallyReceivedNotifier, Map<String, Set<String>>>(
      LocallyReceivedNotifier.new,
    );

/// Acumula los ids de bulto recibidos localmente por envío.
class LocallyReceivedNotifier extends Notifier<Map<String, Set<String>>> {
  @override
  Map<String, Set<String>> build() => <String, Set<String>>{};

  void add(String shipmentId, String unitId) {
    final next = {...state};
    next[shipmentId] = {...?next[shipmentId], unitId};
    state = next;
  }

  Set<String> forShipment(String shipmentId) =>
      state[shipmentId] ?? const <String>{};
}
