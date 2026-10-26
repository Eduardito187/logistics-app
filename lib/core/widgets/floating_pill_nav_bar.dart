import 'package:flutter/material.dart';

import '../navigation/app_nav.dart';
import '../theme/app_colors.dart';

/// Barra de navegación inferior FLOTANTE tipo píldora. Cinco pestañas: cuatro
/// laterales (Inicio, Tareas, Avisos, Perfil) y una central grande y elevada
/// (la acción estrella del rol). TODAS son pestañas: cambian el contenido en la
/// misma pantalla (no redirigen). El ítem activo resalta en rojo de marca.
///
/// Flota POR ENCIMA del contenido (el shell usa `extendBody: true`): se ve el
/// contenido a los lados de la píldora. La onda al tocar queda recortada dentro.
///
/// Índices: 0 Inicio · 1 Tareas · 2 Centro · 3 Avisos · 4 Perfil.
class FloatingPillNavBar extends StatelessWidget {
  const FloatingPillNavBar({
    required this.sideTabs,
    required this.currentIndex,
    required this.onTap,
    required this.centerLabel,
    required this.centerIcon,
    super.key,
  });

  /// Las cuatro pestañas laterales, en orden: Inicio, Tareas, Avisos, Perfil.
  final List<NavTab> sideTabs;

  /// Índice activo 0..4 (2 = pestaña central).
  final int currentIndex;
  final ValueChanged<int> onTap;

  final String centerLabel;
  final IconData centerIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pillColor = isDark ? AppColors.nightSurfaceHigh : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E6EA);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        // Align (no Center): centra en horizontal en tablets SIN expandir en
        // vertical (Center estiraba la barra a toda la pantalla).
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Material(
                    color: pillColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(color: borderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: 66,
                      child: Row(
                        children: [
                          _NavItem(
                            tab: sideTabs[0],
                            selected: currentIndex == 0,
                            onTap: () => onTap(0),
                          ),
                          _NavItem(
                            tab: sideTabs[1],
                            selected: currentIndex == 1,
                            onTap: () => onTap(1),
                          ),
                          // Hueco para el botón central (que va en el Stack).
                          const SizedBox(width: 72),
                          _NavItem(
                            tab: sideTabs[2],
                            selected: currentIndex == 3,
                            onTap: () => onTap(3),
                          ),
                          _NavItem(
                            tab: sideTabs[3],
                            selected: currentIndex == 4,
                            onTap: () => onTap(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pestaña central elevada (índice 2). Es una pestaña más.
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: _CenterButton(
                      label: centerLabel,
                      icon: centerIcon,
                      selected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una pestaña lateral: ícono (con onda circular sobre el ícono) + etiqueta.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    const activeColor = AppColors.brand;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkResponse(
              onTap: onTap,
              radius: 24,
              containedInkWell: false,
              highlightShape: BoxShape.circle,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: 0.14)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 22,
                  color: selected ? activeColor : muted,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tab.label,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? activeColor : muted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pestaña central elevada: círculo grande de marca. Solo ícono. Cuando está
/// activa lleva un anillo claro alrededor (para que se note que es la pestaña
/// seleccionada). Su onda se recorta al círculo.
class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppColors.brand.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brand, AppColors.brandDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
