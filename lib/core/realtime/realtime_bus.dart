import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pusher_socket.dart';

/// Temas de tiempo real. El backend dice qué canales tiene cada tema para el
/// usuario (`GET /app/broadcasting/config` → `channels`); la app no arma
/// nombres de canal ni sabe de ciudades o permisos.
abstract final class RealtimeTopic {
  /// Canal propio del usuario: avisos y notificaciones.
  static const String user = 'user';

  /// Posiciones de la flota en vivo.
  static const String fleet = 'fleet';

  /// Planes y corrida de planificación.
  static const String planning = 'planning';

  /// Pedidos por preparar y su armado (escaneos, etiquetas, camión).
  static const String picking = 'picking';

  /// Lo que ve una tienda: pedidos que llegan, listos para retirar, retirados.
  static const String store = 'store';

  /// Cambios de estado de un pedido (seguimiento).
  static const String tracking = 'tracking';

  /// Operación del día: alertas de telemetría y números del tablero.
  static const String operations = 'operations';

  /// Carga del camión (escaneos de carga y entregas asignadas).
  static const String loading = 'loading';
}

/// Punto de encuentro entre las pantallas y la conexión: las pantallas se
/// anotan a un tema mientras están a la vista y reciben sus eventos. No abre
/// ninguna conexión (eso lo hace `RealtimeHub`), así que una pantalla suelta
/// —o un test— puede usarlo sin red.
class RealtimeBus {
  final Map<String, List<void Function(RealtimeEvent)>> _listeners = {};

  /// Lo fija la conexión: se llama cuando un tema pasa a tener (o deja de
  /// tener) alguien escuchando, para suscribirse solo a lo que se usa.
  void Function(String topic, bool wanted)? onDemand;

  /// Temas con alguien escuchando.
  Set<String> get topics => {
    for (final entry in _listeners.entries)
      if (entry.value.isNotEmpty) entry.key,
  };

  /// Escucha los eventos de [topic]. Devuelve cómo dejar de escuchar.
  void Function() listen(String topic, void Function(RealtimeEvent) onEvent) {
    final list = _listeners.putIfAbsent(topic, () => []);
    list.add(onEvent);
    if (list.length == 1) onDemand?.call(topic, true);
    var cancelled = false;
    return () {
      if (cancelled) return;
      cancelled = true;
      list.remove(onEvent);
      if (list.isEmpty) onDemand?.call(topic, false);
    };
  }

  /// Entrega [event] a quienes escuchan [topic].
  void dispatch(String topic, RealtimeEvent event) {
    for (final listener in [...?_listeners[topic]]) {
      listener(event);
    }
  }
}

final realtimeBusProvider = Provider<RealtimeBus>((ref) => RealtimeBus());

/// Temas que AHORA llegan por socket (conectado y suscrito).
class RealtimeLive extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void set(Set<String> topics) {
    if (topics.length == state.length && topics.containsAll(state)) return;
    state = Set.unmodifiable(topics);
  }
}

final realtimeLiveProvider = NotifierProvider<RealtimeLive, Set<String>>(
  RealtimeLive.new,
);

/// ¿[topic] está llegando por socket? Mientras sea `true` la pantalla NO
/// refresca por tiempo; si es `false` (entorno sin sockets, conexión caída o
/// tema sin canales) usa su refresco de respaldo.
final realtimeTopicLiveProvider = Provider.family<bool, String>(
  (ref, topic) =>
      ref.watch(realtimeLiveProvider.select((live) => live.contains(topic))),
);
