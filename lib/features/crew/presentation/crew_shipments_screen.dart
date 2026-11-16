import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/nav_clearance.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import '../../driver/presentation/controllers/driver_controllers.dart';
import '../../driver/presentation/driver_route_status.dart';
import '../../driver/presentation/widgets/assignment_header.dart';

/// Pantalla principal del TRIPULANTE (ayudante del camión): SOLO LECTURA.
///
/// Muestra el camión al que lo asignaron y los envíos de ese camión para la
/// fecha elegida (hoy = en curso; otras fechas = programados). No hay acciones
/// de carga/entrega: eso es del chofer. Para ver el detalle de un pedido, toca
/// una parada (abre "Consultar pedido") o escanea una etiqueta.
///
/// Reutiliza a propósito los providers de lectura del chofer
/// (`myCrewProvider` / `driverRouteProvider`): es el MISMO dato del mismo
/// camión y comparten caché, así no se le pega dos veces al backend. El
/// alcance (que el tripulante solo vea SU camión) lo aplica el servidor.
class CrewShipmentsScreen extends ConsumerWidget {
  const CrewShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final crewAsync = ref.watch(myCrewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis envíos'),
        actions: [
          IconButton(
            tooltip: 'Elegir fecha',
            icon: const AnimatedAppIcon(AppIcon.myDay),
            onPressed: () => _pickDate(context, ref, date),
          ),
          IconButton(
            tooltip: 'Consultar o escanear una etiqueta',
            icon: const AnimatedAppIcon(AppIcon.scan),
            onPressed: () => context.push('/lookup'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: crewAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        // Un 404 es el caso NORMAL "no me asignaron a ningún camión": se muestra
        // un vacío amable, no un error rojo. Cualquier otro fallo (red, 5xx) sí
        // ofrece reintentar.
        error: (error, _) => _NoAssignment(
          date: date,
          isError: !(error is ApiException && error.status == 404),
          onRetry: () => ref.invalidate(myCrewProvider),
          onPickDate: () => _pickDate(context, ref, date),
        ),
        data: (crew) => _CrewRouteBody(crew: crew, date: date),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'Ver envíos del día',
      locale: const Locale('es'),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).select(picked);
    }
  }
}

/// Cuerpo con la asignación del día y la lista de envíos del camión.
class _CrewRouteBody extends ConsumerWidget {
  const _CrewRouteBody({required this.crew, required this.date});

  final MyCrew crew;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(driverRouteProvider);
    return Column(
      children: [
        AssignmentHeader(crew: crew),
        _DateStrip(date: date),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(driverRouteProvider),
            child: routeAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _RouteError(
                date: date,
                onRetry: () => ref.invalidate(driverRouteProvider),
              ),
              data: (route) => _StopsList(route: route),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lista de paradas (envíos) del camión, de solo lectura y en orden.
class _StopsList extends StatelessWidget {
  const _StopsList({required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    final stops = [...route.stops]..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (stops.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
          const EmptyState(
            icon: AppIcon.route,
            title: 'Sin envíos este día',
            message: 'Cuando el camión tenga pedidos programados aparecerán acá.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, navScrollBottomPadding(context)),
      itemCount: stops.length,
      itemBuilder: (context, index) =>
          _CrewStopTile(position: index + 1, stop: stops[index]),
    );
  }
}

/// Tarjeta de un envío/parada: pedido, cliente, dirección, productos y estado.
/// Sin nada recortado y sin UUID. Al tocarla abre "Consultar pedido".
class _CrewStopTile extends StatelessWidget {
  const _CrewStopTile({required this.position, required this.stop});

  final int position;
  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = stop.orderReference ?? 'Pedido $position';
    final destination = stop.destinationNodeName;
    final units = stop.unitsTotal ?? stop.items.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/lookup', extra: stop.orderReference),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: scheme.primary.withValues(alpha: 0.14),
                    child: Text(
                      '$position',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    stopStatusLabel(stop.status),
                    tone: stopTone(stop.status),
                    icon: stopAppIcon(stop.status),
                  ),
                ],
              ),
              if (stop.customerName != null) ...[
                const SizedBox(height: 8),
                Text(
                  stop.customerName!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              if (stop.address != null) ...[
                const SizedBox(height: 2),
                Text(
                  stop.address!,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const AnimatedAppIcon(AppIcon.orders, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    units == 1 ? '1 producto' : '$units productos',
                    style: TextStyle(color: scheme.outline),
                  ),
                  if (destination != null) ...[
                    const SizedBox(width: 12),
                    const AnimatedAppIcon(AppIcon.pickupStore, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        destination,
                        style: TextStyle(color: scheme.outline),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Franja con la fecha que se está mirando y un atajo para volver a hoy.
class _DateStrip extends ConsumerWidget {
  const _DateStrip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday
        ? 'Hoy, ${DateFormat('d MMM', 'es').format(date)}'
        : DateFormat("EEEE d 'de' MMMM", 'es').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
      child: Row(
        children: [
          const AnimatedAppIcon(AppIcon.myDay, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _capitalize(label),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isToday)
            TextButton(
              onPressed: () =>
                  ref.read(selectedDateProvider.notifier).select(DateTime.now()),
              child: const Text('Hoy'),
            ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Vacío amable cuando el tripulante no tiene camión asignado (404) o falló la
/// consulta (red/5xx, con reintento).
class _NoAssignment extends StatelessWidget {
  const _NoAssignment({
    required this.date,
    required this.isError,
    required this.onRetry,
    required this.onPickDate,
  });

  final DateTime date;
  final bool isError;
  final VoidCallback onRetry;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _DateStrip(date: date),
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        EmptyState(
          icon: isError ? AppIcon.cloudOff : AppIcon.deliver,
          title: isError
              ? 'No se pudo cargar'
              : 'No estás asignado a un camión',
          message: isError
              ? 'Revisá tu conexión e intentá de nuevo.'
              : 'Cuando te asignen a un camión verás acá sus envíos. '
                    'Probá con otra fecha si tenías un viaje programado.',
          action: FilledButton(
            onPressed: isError ? onRetry : onPickDate,
            child: Text(isError ? 'Reintentar' : 'Elegir otra fecha'),
          ),
        ),
      ],
    );
  }
}

/// Error al traer la hoja de ruta del camión (con la asignación ya resuelta).
class _RouteError extends StatelessWidget {
  const _RouteError({required this.date, required this.onRetry});

  final DateTime date;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
        EmptyState(
          icon: AppIcon.cloudOff,
          title: 'No se pudieron cargar los envíos',
          message: 'Revisá tu conexión e intentá de nuevo.',
          action: FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ),
      ],
    );
  }
}
