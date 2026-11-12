import '../icons/icons.dart';

/// Widgets de la pantalla de inicio del teléfono (Android: AppWidgets; iOS:
/// WidgetKit). El [backendKey] es el `kind` del canal nativo
/// `bo.com.dismac/widgets`: lo comparten Dart, Kotlin y Swift, no cambiarlo.
enum HomeWidgetKind {
  nextDelivery(
    backendKey: 'next_delivery',
    label: 'Próxima entrega',
    description: 'Parada en curso, cliente y hora estimada.',
    icon: AppIcon.deliver,
  ),
  routeDay(
    backendKey: 'route_day',
    label: 'Mi ruta de hoy',
    description: 'Entregadas, pendientes y fallidas del día.',
    icon: AppIcon.route,
  ),
  pickingPending(
    backendKey: 'picking_pending',
    label: 'Pedidos por preparar',
    description: 'Pedidos por preparar y planificados.',
    icon: AppIcon.orders,
  ),
  storeReceptions(
    backendKey: 'store_receptions',
    label: 'Recepción en tienda',
    description: 'Envíos en camino y pedidos para recojo.',
    icon: AppIcon.receive,
  ),
  supervisorSummary(
    backendKey: 'supervisor_summary',
    label: 'Resumen del día',
    description: 'Entregas, alertas y camiones en ruta.',
    icon: AppIcon.dashboard,
  ),
  quickScan(
    backendKey: 'quick_scan',
    label: 'Escanear',
    description: 'Abre el escáner de tu tarea con un toque.',
    icon: AppIcon.scan,
  );

  const HomeWidgetKind({
    required this.backendKey,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Clave del widget en el canal nativo.
  final String backendKey;

  /// Nombre visible en Ajustes (y en el selector de widgets del sistema).
  final String label;

  /// Descripción corta para Ajustes.
  final String description;

  /// Ícono animado DisTrack del widget.
  final AppIcon icon;

  /// Kind a partir de su clave del canal, o `null` si no se conoce.
  static HomeWidgetKind? fromBackendKey(String key) {
    for (final kind in values) {
      if (kind.backendKey == key) return kind;
    }
    return null;
  }
}
