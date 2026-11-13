import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/icons/icons.dart';
import '../../../../../core/layout/breakpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/driver_controllers.dart';
import '../../controllers/locally_settled_stops.dart';
import '../../failed_delivery_screen.dart';
import '../../pod_screen.dart';
import '../../scan_mode.dart';
import '../../scan_units_screen.dart';
import 'delivery_sheet.dart';

/// Abre un paso de la entrega y, al volver, refresca la ruta y el estado de la
/// entrega (la parada pudo cerrarse y la siguiente pasa a ser la actual).
Future<void> openDeliveryStep(
  BuildContext context,
  WidgetRef ref,
  DriverRouteStop stop,
  Widget screen,
) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));
  if (!context.mounted) return;
  ref
    ..invalidate(driverRouteProvider)
    ..invalidate(deliveryStateProvider(stop.shipmentId));
}

Widget unloadScreenFor(DriverRouteStop stop) => ScanUnitsScreen(
  mode: ScanMode.unload,
  shipmentId: stop.shipmentId,
  nodeId: stop.id,
  title: 'Escanear productos · parada ${stop.sequence}',
);

/// Botones del pie según el paso de la entrega:
/// - en curso: "Entregar pedido" (con foto obligatoria), "Escanear productos"
///   (QR o código de barras de las etiquetas) y "No se pudo entregar";
/// - ya cerrada (entregada o fallida): "Siguiente entrega".
class DeliveryActionsBar extends ConsumerWidget {
  const DeliveryActionsBar({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Cerrada" se decide por el estado EFECTIVO de ESTA parada: lo que el
    // chofer resolvió en este teléfono (POD/fallida ya hacen `settle`) o el
    // estado de la parada del backend. NUNCA por `deliveryStateProvider` (el
    // estado de la ENTREGA del envío): si el backend devolvía el envío como
    // "delivered" por su cuenta, aparecía "Siguiente entrega" para una parada
    // que el chofer NO había entregado y, al tocarla, la marcaba entregada.
    final settled = ref.watch(locallySettledStopsProvider);
    final closed =
        effectiveStopStatus(stop, settled) != DriverRouteStopStatus.pending;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: closed
                  ? FilledButton.icon(
                      // La parada YA está resuelta (el POD/fallida hicieron
                      // `settle`): este botón solo refresca la ruta para pasar a
                      // la siguiente. NUNCA marca la parada por su cuenta (eso
                      // entregaba paradas que el chofer no había entregado).
                      onPressed: () => ref.invalidate(driverRouteProvider),
                      icon: const AnimatedAppIcon(AppIcon.arrowForward),
                      label: const Text('Siguiente entrega'),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Resumen compacto del cliente + acceso a los DATOS del
                        // pedido (modal bajo demanda).
                        _DeliverySummary(stop: stop),
                        const SizedBox(height: 10),
                        // Las 3 acciones en UN grupo de botones en una sola fila
                        // (antes ocupaban 2 filas): "Entregar" destacado y las
                        // otras dos al lado. Ocupa menos alto → más mapa visible.
                        _ActionGroup(
                          onDeliver: () => openDeliveryStep(
                            context,
                            ref,
                            stop,
                            PodScreen(stop: stop),
                          ),
                          onFailed: () => openDeliveryStep(
                            context,
                            ref,
                            stop,
                            FailedDeliveryScreen(stop: stop),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Las dos acciones del paso en UN grupo compacto de una sola fila:
/// "Entregar" (acción principal, relleno de marca; el POD YA escanea el
/// producto, toma la foto y la firma) y "No se pudo" (en rojo). Antes había un
/// tercer botón "Escanear" suelto: era redundante (la entrega ya escanea) y
/// confundía, así que se quitó.
class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.onDeliver, required this.onFailed});

  final VoidCallback onDeliver;
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      // IntrinsicHeight: los segmentos miden su contenido (ícono + etiqueta) y
      // el divisor iguala al más alto. Así crece con "letra grande" sin
      // desbordar (antes un alto fijo cortaba 2px).
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Segment(
                icon: AppIcon.capture,
                label: 'Entregar',
                onTap: onDeliver,
                background: AppColors.brand,
                foreground: Colors.white,
              ),
            ),
            const _GroupDivider(),
            Expanded(
              child: _Segment(
                icon: AppIcon.cancel,
                label: 'No se pudo',
                onTap: onFailed,
                foreground: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un segmento del grupo: ícono arriba + etiqueta abajo, todo tocable.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.foreground,
    this.background,
  });

  final AppIcon icon;
  final String label;
  final VoidCallback onTap;
  final Color foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedAppIcon(icon, size: 22, color: foreground),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divisor fino entre segmentos del grupo.
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Fila compacta (siempre visible en la barra) con el cliente de la parada y un
/// botón "Ver pedido" que abre los DATOS completos (teléfono, dirección,
/// productos) en un modal. Reemplaza a la hoja que antes tapaba medio mapa.
class _DeliverySummary extends StatelessWidget {
  const _DeliverySummary({required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        stop.customerName ?? stop.orderReference ?? 'Parada ${stop.sequence}';
    final reference = stop.orderReference;
    return Material(
      key: const Key('delivery-summary'),
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDeliveryDetailsSheet(context, stop),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      reference == null
                          ? 'Toca para ver el pedido'
                          : 'Pedido $reference',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Chevron como afordancia de "abrir" (toda la fila es el botón):
              // evita un botón con texto que, con letra grande, desbordaba.
              const AnimatedAppIcon(
                AppIcon.chevronRight,
                size: 22,
                excludeFromSemantics: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Iniciales (1-2) del nombre para el avatar del resumen.
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}
