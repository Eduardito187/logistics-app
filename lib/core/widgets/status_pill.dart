import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pill_tone.dart';

// Se reexporta [PillTone] (movido a su propio archivo por SRP) para no romper a
// quienes importan `widgets/status_pill.dart`.
export 'pill_tone.dart';

/// Chip de estado con color semántico. Para estados de envío, entrega, vehículo.
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.tone = PillTone.neutral,
    this.icon,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  Color get _color => switch (tone) {
    PillTone.neutral => const Color(0xFF607080),
    PillTone.info => AppColors.info,
    PillTone.success => AppColors.success,
    PillTone.warning => AppColors.warning,
    PillTone.danger => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
