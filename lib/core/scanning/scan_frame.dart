import 'package:flutter/material.dart';

/// Overlay de guía del escáner: el recuadro central y el texto de ayuda.
///
/// Lo usa internamente [ScannerScreen]; se mantiene aparte (una clase por
/// archivo) porque es una pieza presentacional independiente de la cámara.
class ScanFrame extends StatelessWidget {
  const ScanFrame({super.key, this.helper});

  final String? helper;

  /// Lado máximo del recuadro guía (teléfonos típicos y tablets).
  static const double maxSide = 260;

  /// Lado del recuadro para un área de [size]: 260 dp como máximo, pero en un
  /// teléfono chico o en horizontal se achica para que entre con el texto de
  /// ayuda sin desbordar.
  static double sideFor(Size size) {
    // 24 dp de margen por lado sobre el lado corto; 55 % del alto como tope
    // para dejar lugar al texto de ayuda en horizontal.
    final fit = size.shortestSide - 48;
    final byHeight = size.height * 0.55;
    final side = fit < byHeight ? fit : byHeight;
    return side < maxSide ? side : maxSide;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => _frame(sideFor(constraints.biggest)),
      ),
    );
  }

  Widget _frame(double side) {
    return Column(
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        const Spacer(),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
            child: Text(
              helper!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
