import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_contrast.dart';
import 'pill_tone.dart';

// Se reexporta [PillTone] (movido a su propio archivo por SRP) para no romper a
// quienes importan `widgets/status_pill.dart`.
export 'pill_tone.dart';

/// Chip de estado con color semántico. Para estados de envío, entrega, vehículo.
///
/// En alto contraste pasa a fondo blanco, borde grueso y texto en el semántico
/// oscuro (≥ 7:1). El lector de pantalla lo anuncia como "Estado: (etiqueta)".
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.tone = PillTone.neutral,
    this.icon,
    this.semanticsLabel,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  /// Texto para lectores de pantalla; por defecto "Estado: [label]".
  final String? semanticsLabel;

  /// Color del tono en el tema normal.
  static Color colorFor(PillTone tone) => switch (tone) {
    PillTone.neutral => const Color(0xFF607080),
    PillTone.info => AppColors.info,
    PillTone.success => AppColors.success,
    PillTone.warning => AppColors.warning,
    PillTone.danger => AppColors.danger,
  };

  /// Color del tono en alto contraste (≥ 7:1 sobre blanco).
  static Color highContrastColorFor(PillTone tone) => switch (tone) {
    PillTone.neutral => AppColors.hcNeutral,
    PillTone.info => AppColors.hcInfo,
    PillTone.success => AppColors.hcSuccess,
    PillTone.warning => AppColors.hcWarning,
    PillTone.danger => AppColors.hcDanger,
  };

  @override
  Widget build(BuildContext context) {
    final high = AppContrast.isHigh(context);
    final color = high ? highContrastColorFor(tone) : colorFor(tone);
    return Semantics(
      container: true,
      label: semanticsLabel ?? 'Estado: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: high ? Colors.white : color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: high ? Border.all(color: color, width: 2) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
              ],
              // Flexible + elipsis: con letra grande o etiquetas largas la
              // pastilla se acorta en vez de desbordar la fila que la contiene.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: high ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
