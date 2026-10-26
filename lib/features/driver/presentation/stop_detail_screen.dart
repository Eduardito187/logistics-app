import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/map/map_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import 'driver_common.dart';
import 'failed_delivery_screen.dart';
import 'pod_screen.dart';
import 'scan_mode.dart';
import 'scan_units_screen.dart';
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
    final done = stop.status == DriverRouteStopStatus.completed;
    final failed = stop.status == DriverRouteStopStatus.failed;

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
                      icon: Icons.receipt_long,
                      text: stop.orderReference!,
                      mono: true,
                    ),
                  if (stop.address != null)
                    InfoRow(icon: Icons.place, text: stop.address!),
                  if (stop.etaAt != null)
                    InfoRow(
                      icon: Icons.schedule,
                      text: 'ETA ${formatTime(stop.etaAt!)}',
                    ),
                  const SizedBox(height: 8),
                  StatusPill(
                    _label(stop.status),
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
                  icon: const Icon(Icons.navigation, size: 28),
                  label: const Text(
                    'Navegar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openMap(context),
                icon: const Icon(Icons.map),
                label: const Text('Ver en el mapa'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ScanUnitsScreen(
                      mode: ScanMode.unload,
                      shipmentId: stop.shipmentId,
                      nodeId: stop.id,
                      title: 'Descargar parada ${stop.sequence}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar bultos'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PodScreen(stop: stop),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Entregado (prueba de entrega)'),
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
              icon: const Icon(Icons.cancel),
              label: const Text('Entrega fallida'),
            ),
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
