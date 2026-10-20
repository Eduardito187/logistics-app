import 'package:flutter/material.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';

/// Encabezado con degradado de marca, logo y bienvenida del login.
///
/// El degradado ocupa todo el ancho; el texto se centra con el ancho del
/// formulario (tablet). Con poco alto (horizontal, teclado) se achica el aire
/// superior para dejar el formulario a la vista.
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
        // Ancho completo hasta el tope: el texto queda alineado al formulario.
        child: SizedBox(
          width: double.infinity,
          child: short
              // Poco alto (horizontal): logo y marca en una fila, sin lema,
              // para que el formulario quede a la vista.
              ? Row(
                  children: [
                    const _Logo(size: 28, padding: 10),
                    const SizedBox(width: 14),
                    Expanded(child: _brand(theme.textTheme.titleLarge)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Logo(size: 44, padding: 14),
                    const SizedBox(height: 20),
                    _brand(theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
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

Widget _brand(TextStyle? style) => Text(
  'Dismac Logística',
  style: style?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
);

/// Logo de la app (camión) sobre un recuadro translúcido.
class _Logo extends StatelessWidget {
  const _Logo({required this.size, required this.padding});

  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Icon(Icons.local_shipping, size: size, color: Colors.white),
      ),
    );
  }
}
