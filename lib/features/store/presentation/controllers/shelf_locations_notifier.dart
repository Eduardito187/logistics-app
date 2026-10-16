import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ubicación en estante capturada localmente por bulto. No hay endpoint: se
/// guarda en memoria para apoyar al personal de tienda tras recibir.
final shelfLocationsProvider =
    NotifierProvider<ShelfLocationsNotifier, Map<String, String>>(
      ShelfLocationsNotifier.new,
    );

/// Mapa en memoria de bulto -> ubicación en estante.
class ShelfLocationsNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => <String, String>{};

  void setLocation(String unitId, String location) {
    state = {...state, unitId: location};
  }
}
