import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/layout/breakpoints.dart';
import '../../controllers/driver_controllers.dart';
import '../../controllers/locally_settled_stops.dart';
import '../../failed_delivery_screen.dart';
import '../../pod_screen.dart';
import '../../scan_mode.dart';
import '../../scan_units_screen.dart';

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
  title: 'Escanear bultos · parada ${stop.sequence}',
);

/// Botones del pie según el paso de la entrega:
/// - en curso: "Entregar pedido" (con foto obligatoria), "Escanear bultos"
///   (QR o código de barras de las etiquetas) y "No se pudo entregar";
/// - ya cerrada (entregada o fallida): "Siguiente entrega".
class DeliveryActionsBar extends ConsumerWidget {
  const DeliveryActionsBar({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      deliveryStateProvider(stop.shipmentId).select((d) => d.value?.status),
    );
    final closed =
        stop.status != DriverRouteStopStatus.pending ||
        status == DeliveryStatus.delivered ||
        status == DeliveryStatus.failed;
    final danger = Theme.of(context).colorScheme.error;

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
                      onPressed: () {
                        // Si el cierre lo sabe el estado de la entrega pero la
                        // ruta todavía no, se avanza ya (sin esperar a la red).
                        if (status == DeliveryStatus.delivered ||
                            status == DeliveryStatus.failed) {
                          ref
                              .read(locallySettledStopsProvider.notifier)
                              .settle(
                                stop.id,
                                status == DeliveryStatus.failed
                                    ? DriverRouteStopStatus.failed
                                    : DriverRouteStopStatus.completed,
                              );
                        }
                        ref.invalidate(driverRouteProvider);
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Siguiente entrega'),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () => openDeliveryStep(
                            context,
                            ref,
                            stop,
                            PodScreen(stop: stop),
                          ),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Entregar pedido'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => openDeliveryStep(
                                  context,
                                  ref,
                                  stop,
                                  unloadScreenFor(stop),
                                ),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text(
                                  'Escanear bultos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: danger,
                                ),
                                onPressed: () => openDeliveryStep(
                                  context,
                                  ref,
                                  stop,
                                  FailedDeliveryScreen(stop: stop),
                                ),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text(
                                  'No se pudo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
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
