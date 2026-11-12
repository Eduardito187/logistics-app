import 'package:flutter/foundation.dart';

/// Un acceso directo del ícono de la app (mantener presionado el ícono en el
/// launcher de Android / 3D-Touch o toque largo en iOS).
@immutable
class AppShortcut {
  const AppShortcut({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.route,
  });

  /// Id estable (el de la `RoleTask`): el sistema lo usa para ordenar y para
  /// los accesos fijados al escritorio.
  final String id;

  /// Texto largo (Android: hasta ~25 caracteres; iOS: título).
  final String title;

  /// Texto corto (Android: hasta ~10 caracteres, se usa si no entra el largo).
  final String shortTitle;

  /// Ruta go_router que abre.
  final String route;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'shortTitle': shortTitle,
    'route': route,
  };

  @override
  bool operator ==(Object other) =>
      other is AppShortcut &&
      other.id == id &&
      other.title == title &&
      other.shortTitle == shortTitle &&
      other.route == route;

  @override
  int get hashCode => Object.hash(id, title, shortTitle, route);
}
