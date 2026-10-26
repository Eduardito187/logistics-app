import 'package:flutter/widgets.dart';

/// Tamaños de pantalla de la app (Material 3 window size classes).
///
/// - compact: teléfonos (incluidos los chicos de 320–360 dp de ancho).
/// - medium: teléfonos grandes en horizontal y tablets chicas.
/// - expanded: tablets grandes y horizontal.
enum WindowSize { compact, medium, expanded }

/// Puntos de corte y medidas de layout compartidas.
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// Ancho máximo de formularios y listas de lectura: en tablets el contenido
  /// no se estira de borde a borde (difícil de leer y de tocar con una mano).
  static const double maxContentWidth = 720;

  /// Ancho máximo de formularios cortos (login, datos de entrega).
  static const double maxFormWidth = 520;

  static WindowSize of(BuildContext context) =>
      sizeFor(MediaQuery.sizeOf(context).width);

  static WindowSize sizeFor(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// Columnas para grillas de tarjetas (inicio, mosaicos): 1 en teléfono,
  /// 2 en tablet chica / horizontal, 3 en tablet grande.
  static int columnsFor(double width) => switch (sizeFor(width)) {
    WindowSize.compact => 1,
    WindowSize.medium => 2,
    WindowSize.expanded => 3,
  };
}
