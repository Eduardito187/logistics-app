import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/widgets/status_pill.dart';
import '../driver_common.dart';
import '../driver_route_status.dart';

/// Tarjeta de una parada en la lista de la ruta: cliente, dirección, ETA y
/// estado; al tocarla abre el detalle.
class StopCard extends StatelessWidget {
  const StopCard({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: stopColor(stop.status),
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
        trailing: StatusPill(
          stopStatusLabel(stop.status),
          tone: stopTone(stop.status),
        ),
        onTap: () => openStopDetail(context, stop),
      ),
    );
  }
}
