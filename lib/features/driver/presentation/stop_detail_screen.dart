import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/map/map_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_common.dart';
import 'failed_delivery_screen.dart';
import 'pod_screen.dart';
import 'widgets/delivery_state_card.dart';
import 'widgets/info_row.dart';
import 'widgets/stop_map_screen.dart';

/// Detalle de una parada: datos del cliente, navegación al punto y las acciones
/// de terreno (descargar, prueba de entrega, entrega fallida).
class StopDetailScreen extends ConsumerWidget {
  const StopDetailScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCoords = stop.lat != null && stop.lng != null;
    // Estado EFECTIVO: incluye lo resuelto en este teléfono (POD/fallida
    // encolados sin señal), así una parada ya entregada aquí no vuelve a mostrar
    // las acciones de terreno aunque el backend todavía la devuelva pendiente.
    final settled = ref.watch(locallySettledStopsProvider);
    final status = effectiveStopStatus(stop, settled);
    final done = status == DriverRouteStopStatus.completed;
    final failed = status == DriverRouteStopStatus.failed;
    // Una parada ya resuelta (entregada o fallida) no se vuelve a operar: se
    // ocultan "Descargar", "Entregar" y "Entrega fallida" (antes seguían
    // visibles tras entregar). Quedan "Navegar" y "Ver en el mapa" para volver
    // al punto, y la tarjeta de estado muestra la evidencia (foto/confirmación).
    final resolved = done || failed;

    return Scaffold(
      appBar: AppBar(title: Text('Parada ${stop.sequence}')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: stop.customerName ?? 'Cliente',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stop.orderReference != null)
                    InfoRow(
                      icon: AppIcon.settle,
                      text: stop.orderReference!,
                      mono: true,
                    ),
                  if (stop.address != null)
                    InfoRow(icon: AppIcon.place, text: stop.address!),
                  // Parada resuelta con hora del backend: HORA DE ENTREGA (o de
                  // la fallida). Si sigue pendiente, la hora estimada (ETA).
                  if (resolved && stop.settledAt != null)
                    InfoRow(
                      icon: done ? AppIcon.success : AppIcon.error,
                      text:
                          '${done ? 'Entregada' : 'Fallida'} '
                          '${formatTime(stop.settledAt!)}',
                    )
                  else if (stop.etaAt != null)
                    InfoRow(
                      icon: AppIcon.pending,
                      text: 'ETA ${formatTime(stop.etaAt!)}',
                    ),
                  const SizedBox(height: 8),
                  StatusPill(
                    _label(status),
                    tone: done
                        ? PillTone.success
                        : failed
                        ? PillTone.danger
                        : PillTone.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DeliveryStateCard(shipmentId: stop.shipmentId),
            const SizedBox(height: 16),
            if (hasCoords) ...[
              // Botón grande: abre la navegación externa (geo:/OSM, sin Google).
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: () => _navigate(context),
                  icon: const AnimatedAppIcon(AppIcon.navigation, size: 28),
                  label: const Text(
                    'Navegar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openMap(context),
                icon: const AnimatedAppIcon(AppIcon.map),
                label: const Text('Ver en el mapa'),
              ),
            ],
            if (!resolved) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PodScreen(stop: stop),
                    ),
                  );
                },
                icon: const AnimatedAppIcon(AppIcon.success),
                label: const Text('Entregar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FailedDeliveryScreen(stop: stop),
                    ),
                  );
                },
                icon: const AnimatedAppIcon(AppIcon.cancel),
                label: const Text('Entrega fallida'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openMap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => StopMapScreen(stop: stop)));
  }

  /// Lanza la navegación externa (geo:/OSM) hacia la parada.
  void _navigate(BuildContext context) {
    final String label =
        stop.customerName ?? stop.address ?? 'Parada ${stop.sequence}';
    unawaited(openExternalNavigation(stop.lat!, stop.lng!, label: label));
  }

  String _label(DriverRouteStopStatus status) => switch (status) {
    DriverRouteStopStatus.completed => 'Entregada',
    DriverRouteStopStatus.failed => 'Fallida',
    DriverRouteStopStatus.pending => 'Pendiente',
    _ => 'Parada',
  };
}
