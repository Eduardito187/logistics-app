import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/user_role.dart';
import '../icons/icons.dart';
import 'role_task.dart';

/// Pestaña activa del shell inferior (0 Inicio, 1 Tareas, 2 Avisos, 3 Perfil).
/// Compartida para poder cambiar de pestaña desde cualquier pantalla (p. ej. el
/// "Ver todo" del Inicio salta a Tareas) sin redirigir a otra ruta.
class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(
  HomeTabNotifier.new,
);

/// Un destino fijo de la barra de navegación inferior. Son universales para
/// todos los roles (todos tienen inicio, tareas, avisos y perfil); la acción
/// central (FAB) sí cambia por rol (ver [centerActionFor]).
@immutable
class NavTab {
  const NavTab({
    required this.label,
    required this.appIcon,
    required this.path,
  });

  /// Etiqueta corta en español bajo el ícono. Siempre visible: para un usuario
  /// mayor el texto es lo que da seguridad para tocar (no solo el ícono).
  final String label;

  /// Ícono animado DisTrack de la pestaña (lo que se dibuja).
  final AppIcon appIcon;

  /// Ruta go_router de la rama del shell.
  final String path;
}

/// Las cuatro pestañas fijas, repartidas 2 + 2 alrededor del botón central:
/// [Inicio] [Tareas]  (FAB)  [Avisos] [Perfil].
const List<NavTab> kPrimaryNavTabs = [
  NavTab(label: 'Inicio', appIcon: AppIcon.home, path: '/home'),
  NavTab(label: 'Tareas', appIcon: AppIcon.tasks, path: '/tareas'),
  NavTab(label: 'Avisos', appIcon: AppIcon.alerts, path: '/avisos'),
  NavTab(label: 'Perfil', appIcon: AppIcon.profile, path: '/perfil'),
];

/// La acción principal del rol: la que va en el botón central (FAB) grande.
/// Se deriva del propio modelo de tareas (`RoleTask.accent == true`), así no
/// hay una segunda fuente de verdad: cada feature ya marca su acción estrella.
///
/// chofer → Entrega en curso · preparador → Pedidos por preparar ·
/// tienda → Recepción · transportista → Escanear al recoger ·
/// supervisor → Tablero del día.
RoleTask? centerActionFor(UserRole role, List<RoleTask> tasks) {
  for (final task in tasks) {
    if (task.accent && task.visibleFor(role)) {
      return task;
    }
  }
  return null;
}
