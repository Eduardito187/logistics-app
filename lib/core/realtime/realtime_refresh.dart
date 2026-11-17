import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'realtime_bus.dart';

/// Cuánto se esperan los avisos seguidos de un mismo cambio antes de volver a
/// pedir los datos (el backend puede mandar varios juntos).
const Duration kRealtimeRefreshDebounce = Duration(milliseconds: 400);

/// Mantiene AL DÍA un provider de lectura con los avisos de tiempo real, en
/// lugar de refrescarlo por tiempo o esperar a que el usuario tire para
/// refrescar.
extension RealtimeRefresh on Ref {
  /// Vuelve a pedir este provider cuando llega por [topic] alguno de los
  /// [events]. Los avisos son señales livianas: el dato se pide de nuevo al
  /// endpoint de siempre. [when] descarta los avisos que no son de lo que
  /// este provider muestra (otro pedido, otro camión, otro día).
  ///
  /// Solo escucha mientras el provider está vivo: al liberarse (salir de la
  /// pantalla) la conexión deja el tema si nadie más lo usa. Sin socket no
  /// hace nada.
  void refreshOnRealtime(
    String topic,
    Set<String> events, {
    bool Function(Map<String, Object?> data)? when,
  }) {
    Timer? debounce;
    final stop = read(realtimeBusProvider).listen(topic, (event) {
      if (!events.contains(event.name)) return;
      if (when != null && !when(event.data)) return;
      debounce?.cancel();
      debounce = Timer(kRealtimeRefreshDebounce, invalidateSelf);
    });
    onDispose(() {
      debounce?.cancel();
      stop();
    });
  }
}

/// ¿El aviso es de [id]? Un aviso sin ese dato (cambio general) cuenta como sí.
bool realtimeMatches(Map<String, Object?> data, String key, String? id) {
  final value = data[key];
  return value is! String || id == null || value == id;
}
