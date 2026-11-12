import '../auth/session.dart';
import '../auth/user_role.dart';
import '../navigation/feature_tasks.dart';
import '../navigation/role_task.dart';
import 'app_shortcut.dart';

/// Máximo de accesos: Android muestra 4 cómodos en casi todos los launchers
/// (y recomienda no pasar de ahí); iOS muestra 4 en el menú del ícono.
const int kMaxAppShortcuts = 4;

/// Tareas del inicio que van como acceso directo, por rol y en orden (la
/// primera, la acción principal del rol). Son ids de `RoleTask` REALES: el
/// acceso abre la misma ruta que la tarjeta del inicio.
const Map<UserRole, List<String>> kRoleShortcutTaskIds = {
  UserRole.driver: [
    'driver-active-delivery',
    'driver-route',
    'driver-load',
    'driver-incident',
  ],
  UserRole.picker: ['picking-orders', 'picking-prepare'],
  UserRole.store: ['store-reception', 'store-pickup'],
  UserRole.carrier: ['carrier-pickup', 'carrier-deliver'],
  UserRole.supervisor: ['sup-fleet', 'sup-alerts', 'sup-dashboard'],
};

/// Textos cortos (Android, ≤ 10 caracteres) por id de tarea.
const Map<String, String> kShortcutShortTitles = {
  'driver-active-delivery': 'Entrega',
  'driver-route': 'Mi ruta',
  'driver-load': 'Carga',
  'driver-incident': 'Incidente',
  'picking-orders': 'Preparar',
  'picking-prepare': 'Ingresar',
  'store-reception': 'Recibir',
  'store-pickup': 'Recojo',
  'carrier-pickup': 'Recoger',
  'carrier-deliver': 'Entregar',
  'sup-fleet': 'Flota',
  'sup-alerts': 'Alertas',
  'sup-dashboard': 'Tablero',
};

/// Accesos directos para [session] a partir de las tareas del inicio [tasks]
/// (las de `featureTasksProvider`). Respeta el mismo filtro rol + permiso que
/// el inicio (`visibleTasksFor`): nunca se ofrece un acceso a algo que el
/// usuario no ve en su inicio.
List<AppShortcut> shortcutsFor(Session session, List<RoleTask> tasks) {
  final ids = kRoleShortcutTaskIds[session.role] ?? const <String>[];
  if (ids.isEmpty) return const [];
  final visible = {
    for (final task in visibleTasksFor(session, tasks)) task.id: task,
  };
  final result = <AppShortcut>[];
  for (final id in ids) {
    final task = visible[id];
    if (task == null) continue;
    result.add(
      AppShortcut(
        id: task.id,
        title: task.label,
        shortTitle: kShortcutShortTitles[task.id] ?? task.label,
        route: task.route,
      ),
    );
    if (result.length == kMaxAppShortcuts) break;
  }
  return result;
}
