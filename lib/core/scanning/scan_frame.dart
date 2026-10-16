import 'package:flutter/material.dart';

/// Overlay de guía del escáner: el recuadro central y el texto de ayuda.
///
/// Lo usa internamente [ScannerScreen]; se mantiene aparte (una clase por
/// archivo) porque es una pieza presentacional independiente de la cámara.
class ScanFrame extends StatelessWidget {
  const ScanFrame({super.key, this.helper});

  final String? helper;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Spacer(),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 48, left: 24, right: 24),
              child: Text(
                helper!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
