import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/stat_tile.dart';
import '../domain/entities/my_day_stats.dart';
import '../domain/route_km_today.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/fleet_ops_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/active_delivery/delivery_status_card.dart';

/// "Mi día": resumen del chofer calculado de la ruta del día (paradas
/// entregadas, fallidas, pendientes, horarios y tiempo promedio por parada).
class MyDayScreen extends ConsumerWidget {
  const MyDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DriverVehicleGate(
      title: 'Mi día',
      builder: (context, vehicleId) {
        final route = ref.watch(driverRouteProvider);
        return AsyncValueView<DriverRoute>(
          value: route,
          onRetry: () => ref.invalidate(driverRouteProvider),
          data: (data) => _MyDayBody(stats: MyDayStats.fromRoute(data)),
        );
      },
    );
  }
}

class _MyDayBody extends StatelessWidget {
  const _MyDayBody({required this.stats});

  final MyDayStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Avance de hoy',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  stats.total == 0
                      ? 'Todavía no tenés paradas para hoy.'
                      : '${stats.attended} de ${stats.total} paradas atendidas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                RouteProgressBar(
                  total: stats.total,
                  completed: stats.attended.clamp(0, stats.total),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Paradas',
            child: MyDayGrid(
              tiles: [
                StatTile(
                  value: '${stats.total}',
                  label: 'Totales',
                  icon: AppIcon.route,
                  color: AppColors.brand,
                ),
                StatTile(
                  value: '${stats.delivered}',
                  label: 'Entregadas',
                  icon: AppIcon.deliverScan,
                  color: AppColors.success,
                ),
                StatTile(
                  value: '${stats.failed}',
                  label: 'No entregadas',
                  icon: AppIcon.cancel,
                  color: AppColors.danger,
                ),
                StatTile(
                  value: '${stats.pending}',
                  label: 'Pendientes',
                  icon: AppIcon.pending,
                  color: AppColors.hcWarning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Tiempos',
            child: MyDayGrid(
              tiles: [
                StatTile(
                  value: _hour(stats.firstSettledAt),
                  label: 'Primera entrega',
                  icon: AppIcon.sun,
                  color: AppColors.info,
                ),
                StatTile(
                  value: _hour(stats.lastSettledAt),
                  label: 'Última entrega',
                  icon: AppIcon.pending,
                  color: AppColors.brandDark,
                ),
                StatTile(
                  value: formatAveragePerStop(stats.averagePerStop),
                  label: 'Promedio por parada',
                  icon: AppIcon.pending,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _RouteKmCard(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => context.push('/driver/route'),
            icon: const AnimatedAppIcon(AppIcon.map),
            label: const Text('Ver ruta del día'),
          ),
        ],
      ),
    );
  }
}

/// Formato de hora creado una vez (no en cada build).
final DateFormat _hourFormat = DateFormat.Hm('es');

String _hour(DateTime? at) =>
    at == null ? '—' : _hourFormat.format(at.toLocal());

/// "18 min", "1 h 05 min" o "—" sin datos suficientes.
String formatAveragePerStop(Duration? d) {
  if (d == null) return '—';
  final minutes = (d.inSeconds / 60).round();
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
}

/// Tarjeta complementaria "Kilómetros de hoy": km recorridos de la ruta del día
/// = odómetro de llegada − odómetro de salida (ver [routeKmToday]).
///
/// Es información de apoyo: en carga o error no muestra nada (sin "Reintentar"),
/// y tampoco aparece si no hay ninguna lectura de odómetro del día.
class _RouteKmCard extends ConsumerWidget {
  const _RouteKmCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(vehicleOdometerReadingsProvider);
    return readings.maybeWhen(
      data: (data) {
        final km = routeKmToday(data, DateTime.now());
        if (km.departureKm == null && km.arrivalKm == null) {
          // Sin lecturas del día: no mostramos la tarjeta.
          return const SizedBox.shrink();
        }
        return SectionCard(
          title: 'Kilómetros de hoy',
          child: _RouteKmBody(km: km),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _RouteKmBody extends StatelessWidget {
  const _RouteKmBody({required this.km});

  final RouteKmToday km;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final traveled = km.traveledKm;

    if (traveled != null) {
      return Row(
        children: [
          const AnimatedAppIcon(AppIcon.speed, color: AppColors.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$traveled km recorridos',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Salida ${km.departureKm} km · Llegada ${km.arrivalKm} km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Falta la llegada: hay salida pero no recorrido calculable (tono neutro).
    final departure = km.departureKm;
    final text = departure != null
        ? 'Salida registrada: $departure km. Falta el odómetro de llegada.'
        : 'Falta el odómetro de salida de hoy.';
    return Row(
      children: [
        AnimatedAppIcon(
          AppIcon.speed,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Rejilla de mosaicos: columnas según el ancho (1 en teléfono chico, 2 en uno
/// típico, hasta 4 en tablets), alto según el contenido (sin desbordes con
/// letra grande).
class MyDayGrid extends StatelessWidget {
  const MyDayGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  static const double _minTileWidth = 140;
  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minTileWidth).floor().clamp(
          1,
          4,
        );
        final tileWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}
