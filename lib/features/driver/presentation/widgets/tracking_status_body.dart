import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/layout/responsive_body.dart';

import '../../../../core/api/export.dart';
import '../../../../core/location/truck_tracking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';

/// Cuerpo de la pantalla de rastreo: estado del GPS automático, parada asociada
/// y contadores (posiciones enviadas, última posición).
class TrackingStatusBody extends ConsumerWidget {
  const TrackingStatusBody({super.key, required this.target});

  final DriverRouteStop? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracking = ref.watch(truckTrackingProvider);
    final fix = tracking.lastFix;
    final running = tracking.active;

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Rastreo automático',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Rastreando sin fix = el anillo de "locating" late mientras
                    // busca; con fix queda fijado (punto sólido); en espera, quieto.
                    AnimatedAppIcon(
                      AppIcon.gps,
                      state: !running
                          ? AppIconState.idle
                          : fix == null
                          ? AppIconState.loading
                          : AppIconState.active,
                      // Rastreo activo = señal semántica (verde), no rojo de
                      // marca; apagado = neutro.
                      color: running
                          ? AppColors.success
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    // Expanded: en teléfonos chicos con letra grande baja de
                    // línea en vez de desbordar.
                    Expanded(
                      child: Text(
                        running ? 'Rastreando' : 'En espera de parada activa',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'La ubicación del camión se envía sola mientras estás en ruta, '
                  'también con la app en segundo plano. No hace falta encender ni '
                  'apagar nada.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (target != null)
            SectionCard(
              title: 'Parada asociada',
              child: Text(
                target!.customerName ?? 'Envío ${target!.shipmentId}',
                style: theme.textTheme.titleMedium,
              ),
            )
          else
            const EmptyState(
              icon: AppIcon.flag,
              title: 'Ruta sin paradas pendientes',
              message: 'El rastreo se reanuda al haber una parada en curso.',
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${tracking.sent}',
                  label: 'Posiciones enviadas',
                  icon: AppIcon.gps,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: running ? 'Activo' : 'En espera',
                  label: 'Estado del rastreo',
                  icon: running ? AppIcon.gps : AppIcon.gpsOff,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatTile(
            value: fix == null
                ? '—'
                : '${fix.lat.toStringAsFixed(4)}, '
                      '${fix.lng.toStringAsFixed(4)}',
            label: 'Última posición',
            icon: AppIcon.place,
          ),
        ],
      ),
    );
  }
}
