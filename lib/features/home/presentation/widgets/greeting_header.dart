import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Saludo cálido del inicio, estilo app de consumo, sobre fondo claro ("Andén").
///
/// Fila con un avatar circular (ícono del rol en rojo de marca sobre un fondo
/// rojo al 12%), el saludo "Hola," atenuado y, debajo, el nombre grande y bold
/// con la etiqueta del rol chica y atenuada. Texto grande y legible para
/// choferes y personal de tienda.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.roleIcon,
    this.onAvatarTap,
  });

  final String name;
  final String roleLabel;
  final IconData roleIcon;

  /// Acción al tocar el avatar (p. ej. abrir el perfil); si es `null`, el
  /// avatar no es interactivo.
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final avatar = Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(roleIcon, color: AppColors.brand, size: 26),
    );

    return Row(
      children: [
        if (onAvatarTap != null)
          Semantics(
            button: true,
            label: 'Perfil',
            child: InkResponse(
              onTap: onAvatarTap,
              radius: 32,
              child: avatar,
            ),
          )
        else
          avatar,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hola,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
