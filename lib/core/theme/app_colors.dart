import 'package:flutter/material.dart';

/// Paleta de marca de la app de campo. Acento fuerte y alto contraste para
/// leerse bajo el sol; superficies oscuras disponibles para turnos de noche.
abstract final class AppColors {
  const AppColors._();

  // Azul corporativo Dismac como color primario de acción.
  static const Color brand = Color(0xFF0B4DA2);
  static const Color brandDark = Color(0xFF07336C);

  // Acento lima/ámbar para llamadas a la acción y estados "en curso"
  // (toma la energía de los mockups sin perder legibilidad al sol).
  static const Color accent = Color(0xFFD7F205);
  static const Color accentInk = Color(0xFF1A1E00);

  // Semánticos de estado operativo.
  static const Color success = Color(0xFF1E8E3E);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1565C0);

  // Superficies oscuras (modo noche / vista de mapa).
  static const Color nightBg = Color(0xFF101418);
  static const Color nightSurface = Color(0xFF1A2026);
  static const Color nightSurfaceHigh = Color(0xFF232B33);
}
