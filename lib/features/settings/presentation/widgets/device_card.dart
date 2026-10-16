import 'package:flutter/material.dart';

import '../../../../core/api/models/device_list_item.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../device_format.dart';

/// Tarjeta de un dispositivo/sesión: nombre, plataforma, última actividad, uuid
/// y acción para revocar. Marca el dispositivo actual y los ya revocados.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    required this.device,
    required this.isCurrent,
    required this.onRevoke,
    super.key,
  });

  final DeviceListItem device;
  final bool isCurrent;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = device.name ?? platformLabel(device.platform);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(switch (device.platform?.toLowerCase()) {
                'android' => Icons.phone_android,
                'ios' => Icons.phone_iphone,
                'web' => Icons.computer,
                _ => Icons.devices,
              }, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      platformLabel(device.platform),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                const StatusPill(
                  'Este dispositivo',
                  tone: PillTone.info,
                  icon: Icons.check_circle_outline,
                )
              else if (device.revoked)
                const StatusPill('Revocado', tone: PillTone.danger),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Última actividad: ${formatDeviceDateTime(device.lastSeenAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            device.uuid,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontFamily: 'monospace',
            ),
          ),
          if (onRevoke != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRevoke,
              icon: const Icon(Icons.logout),
              label: Text(
                isCurrent ? 'Revocar este dispositivo' : 'Revocar sesión',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
