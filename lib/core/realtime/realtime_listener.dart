import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pusher_socket.dart';
import 'realtime_bus.dart';

/// Escucha un tema de tiempo real mientras [child] está en pantalla y entrega
/// sus eventos a [onEvent]. Al salir de la pantalla deja de escuchar (y la
/// conexión se desuscribe del tema si nadie más lo usa).
///
/// El backend puede mandar varios avisos seguidos por un mismo cambio: se
/// juntan durante [debounce] y se entregan todos de una vez, así la pantalla
/// vuelve a pedir sus datos una sola vez.
class RealtimeListener extends ConsumerStatefulWidget {
  const RealtimeListener({
    super.key,
    required this.topic,
    required this.onEvent,
    required this.child,
    this.debounce = const Duration(milliseconds: 400),
  });

  final String topic;
  final void Function(RealtimeEvent event) onEvent;
  final Widget child;
  final Duration debounce;

  @override
  ConsumerState<RealtimeListener> createState() => _RealtimeListenerState();
}

class _RealtimeListenerState extends ConsumerState<RealtimeListener> {
  void Function()? _stop;
  Timer? _flush;
  final List<RealtimeEvent> _pending = [];

  @override
  void initState() {
    super.initState();
    _stop = ref.read(realtimeBusProvider).listen(widget.topic, _onEvent);
  }

  void _onEvent(RealtimeEvent event) {
    if (!mounted) return;
    _pending.add(event);
    _flush?.cancel();
    _flush = Timer(widget.debounce, _deliver);
  }

  void _deliver() {
    if (!mounted) return;
    final events = [..._pending];
    _pending.clear();
    events.forEach(widget.onEvent);
  }

  @override
  void dispose() {
    _flush?.cancel();
    _stop?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
