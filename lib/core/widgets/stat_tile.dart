import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_contrast.dart';

/// Mosaico de métrica: número grande + etiqueta. Usado en los resúmenes de
/// chofer y supervisor (estilo "finanzas" de los mockups).
///
/// Para lectores de pantalla es un solo nodo "etiqueta: valor". En alto
/// contraste: fondo blanco, borde grueso y los semánticos de marca pasan a su
/// versión oscura.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.semanticsLabel,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  /// Texto para lectores de pantalla; por defecto "[label]: [value]".
  final String? semanticsLabel;

  /// Versión de alto contraste de los colores semánticos conocidos; el resto
  /// queda igual (lo elige quien llama).
  static Color highContrastTint(Color color) {
    if (color == AppColors.success) return AppColors.hcSuccess;
    if (color == AppColors.warning) return AppColors.hcWarning;
    if (color == AppColors.danger) return AppColors.hcDanger;
    if (color == AppColors.info) return AppColors.hcInfo;
    if (color == AppColors.brand) return AppColors.hcBrand;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final high = AppContrast.isHigh(context);
    final base = color ?? theme.colorScheme.primary;
    final tint = high ? highContrastTint(base) : base;
    // El número se lee antes de saber qué mide si se dejan nodos sueltos: se
    // anuncia todo junto.
    return Semantics(
      container: true,
      label: semanticsLabel ?? '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: high ? Colors.white : tint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: high
              ? Border.all(color: tint, width: 2)
              : Border.all(color: tint.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: tint, size: 24),
              const SizedBox(height: 8),
            ],
            // En celdas angostas (grilla de 2 en teléfono chico) el número se
            // achica en vez de desbordar o cortarse.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tint,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
