import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/usecases/acknowledge_alert.dart';
import '../controllers/supervisor_controllers.dart';
import '../supervisor_labels.dart';
import '../vehicle_label.dart';

/// Tarjeta de una alerta de telemetría, con acción de reconocimiento.
class AlertCard extends ConsumerStatefulWidget {
  const AlertCard({super.key, required this.alert});

  final Alert alert;

  @override
  ConsumerState<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends ConsumerState<AlertCard> {
  bool _acknowledging = false;

  Future<void> _acknowledge() async {
    final alert = widget.alert;
    setState(() => _acknowledging = true);
    try {
      await ref.read(acknowledgeAlertProvider)(alert.id);
      ref.invalidate(alertsProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final acknowledged = alert.acknowledgedAt != null;
    final detail = alertDetailText(alert.detail);

    return SectionCard(
      title: alertTypeLabel(alert.type),
      trailing: StatusPill(
        alertSeverityLabel(alert.severity),
        tone: alertSeverityTone(alert.severity),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vehicleLabel(ref, alert.vehicleId)),
          const SizedBox(height: 4),
          Text('Ocurrió: ${formatHour(alert.occurredAt)}'),
          if (detail != null) ...[const SizedBox(height: 4), Text(detail)],
          const SizedBox(height: 12),
          if (acknowledged)
            Row(
              children: [
                // Éxito del reconocimiento: la key remonta el ícono (y su
                // animación) si llega un reconocimiento nuevo.
                AnimatedAppIcon(
                  AppIcon.success,
                  key: ValueKey(alert.acknowledgedAt),
                  state: AppIconState.success,
                  color: AppColors.success,
                  size: 20,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Reconocida ${formatHour(alert.acknowledgedAt!)}',
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: _acknowledging ? null : _acknowledge,
              // Mientras se envía el reconocimiento, el tilde "carga".
              icon: AnimatedAppIcon(
                AppIcon.check,
                state: _acknowledging
                    ? AppIconState.loading
                    : AppIconState.idle,
                excludeFromSemantics: true,
              ),
              label: Text(_acknowledging ? 'Reconociendo…' : 'Reconocer'),
            ),
        ],
      ),
    );
  }
}
