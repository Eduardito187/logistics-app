import 'package:flutter/material.dart';

/// Dispara [onLoadMore] cuando el desplazamiento se acerca al final de la
/// lista que envuelve (scroll infinito).
///
/// Se usan las notificaciones de scroll y no un pie "que se construye al
/// verse": dentro de un `SliverMainAxisGroup` el pie se construye siempre,
/// esté o no en pantalla, y pediría la página 2 sin que nadie desplazara nada.
///
/// [onLoadMore] se llama varias veces durante un mismo desplazamiento: quien
/// la implementa debe ignorar los pedidos repetidos (el notificador corta por
/// `loadingMore` / `hasMore`). Devuelve `false` siempre, así el
/// `RefreshIndicator` de arriba sigue recibiendo las notificaciones.
class LoadMoreOnScroll extends StatelessWidget {
  const LoadMoreOnScroll({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.triggerExtent = 600,
  });

  /// Qué hacer al acercarse al final.
  final VoidCallback onLoadMore;

  /// La lista desplazable (normalmente un `CustomScrollView`).
  final Widget child;

  /// A cuántos px del final se pide la página siguiente. Holgado a propósito:
  /// con buena señal la próxima página ya está cuando el dedo llega al borde.
  final double triggerExtent;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        // depth > 0 = otra lista anidada (p. ej. un carrusel dentro de una
        // tarjeta): no es el final de ESTA lista.
        if (notification.depth != 0) return false;
        final metrics = notification.metrics;
        if (metrics.axis != Axis.vertical) return false;
        if (metrics.extentAfter <= triggerExtent) onLoadMore();
        return false;
      },
      child: child,
    );
  }
}
