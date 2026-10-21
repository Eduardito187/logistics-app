import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';

/// Encabezado del login con el degradado de marca DisTrack y el logo.
///
/// El degradado (rojo Dismac) ocupa todo el ancho; el logo y el lema se centran
/// con el ancho del formulario (tablet). Con poco alto (horizontal, teclado) se
/// achica el aire superior y se muestra el logo compacto, sin lema.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final short = MediaQuery.sizeOf(context).height < 480;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        topPadding + (short ? 16 : 48),
        24,
        short ? 20 : 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // Mismo ancho que el formulario (menos su padding lateral de 24).
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxFormWidth - 48,
        ),
        child: SizedBox(
          width: double.infinity,
          child: short
              // Poco alto (horizontal): solo el logo compacto, alineado a la
              // izquierda, para dejar el formulario a la vista.
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    'assets/brand/distrack-logo-inverse.svg',
                    height: 30,
                    semanticsLabel: 'DisTrack',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wordmark + lema de marca ("DE ANDÉN A PUERTA.").
                    SvgPicture.asset(
                      'assets/brand/distrack-wordmark-tagline-inverse.svg',
                      height: 72,
                      semanticsLabel: 'DisTrack · DE ANDÉN A PUERTA.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'La operación de reparto y tienda, en una sola app.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
