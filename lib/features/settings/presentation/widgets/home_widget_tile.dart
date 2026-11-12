import 'package:flutter/material.dart';

import '../../../../core/home_widgets/home_widget_kind.dart';
import '../../../../core/icons/icons.dart';

/// Un widget de la pantalla de inicio en Ajustes: nombre, descripción, switch
/// "Mostrar en el selector" (Android) y botón "Agregar a la pantalla de
/// inicio" (si el launcher lo permite).
class HomeWidgetTile extends StatelessWidget {
  const HomeWidgetTile({
    super.key,
    required this.kind,
    required this.enabled,
    this.onToggle,
    this.onPin,
  });

  final HomeWidgetKind kind;

  /// ¿Está en el selector de widgets?
  final bool enabled;

  /// Cambio del switch; `null` oculta el switch (iOS o "Escanear", que va
  /// siempre).
  final ValueChanged<bool>? onToggle;

  /// Agregar a la pantalla de inicio; `null` oculta el botón.
  final VoidCallback? onPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toggle = onToggle;
    final pin = onPin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedAppIcon(
              kind.icon,
              state: enabled ? AppIconState.active : AppIconState.idle,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(kind.description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        if (toggle != null)
          SwitchListTile(
            key: Key('homeWidgetSwitch_${kind.backendKey}'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar en el selector'),
            value: enabled,
            onChanged: toggle,
          ),
        if (pin != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: Key('homeWidgetPin_${kind.backendKey}'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: pin,
            icon: const AnimatedAppIcon(
              AppIcon.add,
              excludeFromSemantics: true,
            ),
            label: const Text(
              'Agregar a la pantalla de inicio',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
