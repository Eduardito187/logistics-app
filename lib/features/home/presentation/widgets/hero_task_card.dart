import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tarjeta "héroe" del inicio: la acción principal del rol, grande y vistosa.
///
/// Gradiente rojo ([AppColors.brand] → [AppColors.brandDark]) en diagonal,
/// radio 24, texto blanco y un botón circular de acción. Toda la tarjeta es
/// tocable. Anima una vez al entrar (fade + leve deslizamiento hacia arriba) y
/// hace una micro-escala al presionar. Con "reducir movimiento" se muestra el
/// estado final, sin animaciones.
class HeroTaskCard extends StatefulWidget {
  const HeroTaskCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.statusLabel,
    this.actionLabel = 'Abrir',
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  /// Etiqueta de estado opcional (p. ej. "En curso") en una pastilla clara.
  final String? statusLabel;

  /// Texto de accesibilidad de la acción (el botón circular con la flecha).
  final String actionLabel;

  @override
  State<HeroTaskCard> createState() => _HeroTaskCardState();
}

class _HeroTaskCardState extends State<HeroTaskCard>
    with SingleTickerProviderStateMixin {
  // Animación de entrada (una sola vez). Nula con reducir movimiento.
  AnimationController? _entry;
  bool _reducedMotion = false;
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced == _reducedMotion && (_entry != null || reduced)) {
      return;
    }
    _reducedMotion = reduced;
    if (reduced) {
      _entry?.dispose();
      _entry = null;
    } else {
      _entry ??=
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 240),
          )..forward();
    }
  }

  @override
  void dispose() {
    _entry?.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_reducedMotion || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Container(
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Ícono decorativo grande y tenue a la derecha.
          Positioned(
            top: -8,
            right: -8,
            child: Icon(
              widget.icon,
              size: 96,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.statusLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.statusLabel!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón circular de acción (decorativo: toca toda la tarjeta).
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.brand,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // Toda la tarjeta es tocable; el ripple se recorta al radio 24.
    Widget card = Semantics(
      button: true,
      label: '${widget.title}. ${widget.actionLabel}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          child: content,
        ),
      ),
    );

    if (_reducedMotion) {
      return card;
    }

    // Micro-escala al presionar (0.98).
    card = AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: card,
    );

    final entry = _entry;
    if (entry == null) {
      return card;
    }

    // Entrada: fade + deslizamiento sutil hacia arriba, una sola vez.
    final curved = CurvedAnimation(parent: entry, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}
