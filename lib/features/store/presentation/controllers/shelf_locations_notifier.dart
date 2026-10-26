import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ubicación en estante capturada localmente por bulto. No hay endpoint: se
/// guarda en memoria para apoyar al personal de tienda tras recibir.
final shelfLocationsProvider =
    NotifierProvider<ShelfLocationsNotifier, Map<String, String>>(
      ShelfLocationsNotifier.new,
    );

/// Mapa en memoria de bulto -> ubicación en estante.
///
/// Acotado a [maxEntries] bultos (se descarta la ubicación cargada hace más
/// tiempo) para que un turno largo no haga crecer la memoria sin límite.
class ShelfLocationsNotifier extends Notifier<Map<String, String>> {
  /// Ubicaciones que se recuerdan a la vez.
  static const int maxEntries = 500;

  @override
  Map<String, String> build() => <String, String>{};

  void setLocation(String unitId, String location) {
    if (state[unitId] == location) return;
    // La ubicación nueva va al final (orden de inserción = más reciente).
    final next = {...state}..remove(unitId);
    next[unitId] = location;
    while (next.length > maxEntries) {
      next.remove(next.keys.first);
    }
    state = next;
  }
}
