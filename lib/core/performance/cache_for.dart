import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Caché corta para providers `autoDispose` de pantallas: el dato sigue vivo
/// [duration] después de que nadie lo escucha, así volver a la pantalla (o ir
/// de la lista al detalle y volver) lo muestra al instante sin spinner ni
/// request. Pasado el plazo se libera como cualquier `autoDispose`.
///
/// Uso dentro del provider: `ref.cacheFor(const Duration(seconds: 60));`
extension CacheForRef on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}

/// Plazos estándar de la app (para no inventar uno por pantalla).
abstract final class CacheTtl {
  /// Datos que cambian durante el turno (ruta, recepciones, listas).
  static const Duration short = Duration(seconds: 60);

  /// Datos casi fijos del turno (tripulación, placas, nodos).
  static const Duration long = Duration(minutes: 10);
}
