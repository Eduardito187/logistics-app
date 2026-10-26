import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/widgets/status_pill.dart';
import '../driver_common.dart';
import '../driver_route_status.dart';

/// Tarjeta de una parada en la lista de la ruta: cliente, dirección, ETA y
/// estado; al tocarla abre el detalle.
class StopCard extends StatelessWidget {
  const StopCard({super.key, required this.stop, this.status});

  final DriverRouteStop stop;

  /// Estado a mostrar si difiere del de la parada (resuelta localmente, sin
  /// sincronizar todavía). `null` = el de [stop].
  final DriverRouteStopStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = this.status ?? stop.status;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: stopColor(status),
          child: Text(
            '${stop.sequence}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          stop.customerName ?? stop.orderReference ?? 'Parada ${stop.sequence}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stop.address != null)
              Text(stop.address!, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (stop.etaAt != null) Text('ETA ${formatTime(stop.etaAt!)}'),
          ],
        ),
        trailing: StatusPill(stopStatusLabel(status), tone: stopTone(status)),
        onTap: () => openStopDetail(context, stop),
      ),
    );
  }
}
