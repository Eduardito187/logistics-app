import '../auth/session.dart';
import '../auth/user_role.dart';
import '../navigation/feature_tasks.dart';
import '../navigation/role_task.dart';
import 'home_widget_kind.dart';

/// Ruta que abre un widget sin sesión (= `AppRoutes.login`). El controller de
/// accesos directos no la navega: la app abre donde corresponda (el login).
const String kHomeWidgetSignedOutRoute = '/login';

/// Ruta de un widget que no es del rol (= `AppRoutes.home`): abre la app sin
/// navegar a ningún flujo.
const String kHomeWidgetNotAllowedRoute = '/home';

/// Widgets que ofrece cada rol, en orden. El supervisor no tiene "Escanear":
/// no tiene ninguna tarea de escaneo propia.
const Map<UserRole, List<HomeWidgetKind>> kRoleHomeWidgetKinds = {
  UserRole.driver: [
    HomeWidgetKind.nextDelivery,
    HomeWidgetKind.routeDay,
    HomeWidgetKind.quickScan,
  ],
  UserRole.picker: [HomeWidgetKind.pickingPending, HomeWidgetKind.quickScan],
  UserRole.store: [HomeWidgetKind.storeReceptions, HomeWidgetKind.quickScan],
  UserRole.carrier: [HomeWidgetKind.quickScan],
  UserRole.supervisor: [HomeWidgetKind.supervisorSummary],
};

/// Tarea de escaneo principal de cada rol (rutas REALES de `RoleTask`):
/// chofer → carga del camión (escaneo de productos), preparador → ingresar
/// pedido (escanear el número), tienda → recepción (escaneo de productos),
/// transportista → escanear al recoger.
const Map<UserRole, String> kQuickScanRoutes = {
  UserRole.driver: '/driver/load',
  UserRole.picker: '/picking/prepare',
  UserRole.store: '/store/reception',
  UserRole.carrier: '/carrier/pickup',
};

/// Rutas fijas de los widgets con datos.
const String kNextDeliveryRoute = '/driver/delivery';
const String kRouteDayRoute = '/driver/route';
const String kPickingPendingRoute = '/picking/orders';
const String kPickingScanRoute = '/picking/prepare';
const String kStoreReceptionsRoute = '/store/reception';
const String kSupervisorSummaryRoute = '/supervisor/dashboard';

/// Widgets del rol [role] (vacío si no tiene).
List<HomeWidgetKind> homeWidgetKindsFor(UserRole role) =>
    kRoleHomeWidgetKinds[role] ?? const [];

/// Ruta que abre el widget [kind] para [role], o `null` si no es del rol.
String? homeWidgetRouteFor(HomeWidgetKind kind, UserRole role) {
  if (!homeWidgetKindsFor(role).contains(kind)) return null;
  return switch (kind) {
    HomeWidgetKind.nextDelivery => kNextDeliveryRoute,
    HomeWidgetKind.routeDay => kRouteDayRoute,
    HomeWidgetKind.pickingPending => kPickingPendingRoute,
    HomeWidgetKind.storeReceptions => kStoreReceptionsRoute,
    HomeWidgetKind.supervisorSummary => kSupervisorSummaryRoute,
    HomeWidgetKind.quickScan => kQuickScanRoutes[role],
  };
}

/// Rutas que un toque en un widget puede abrir para [session]: las de los
/// widgets de su rol (incluido el "Escanear" interno de "Pedidos por
/// preparar") que ADEMÁS son tareas visibles en su inicio (mismo filtro rol +
/// permiso que `visibleTasksFor`). Lo usa el controller de accesos directos
/// para aceptar los toques de widgets sin abrir pantallas de otro rol.
Set<String> homeWidgetRoutesFor(Session session, List<RoleTask> tasks) {
  final candidates = <String>{
    for (final kind in homeWidgetKindsFor(session.role))
      ?homeWidgetRouteFor(kind, session.role),
    if (homeWidgetKindsFor(
      session.role,
    ).contains(HomeWidgetKind.pickingPending))
      kPickingScanRoute,
  };
  final visible = {
    for (final task in visibleTasksFor(session, tasks)) task.route,
  };
  return candidates.intersection(visible);
}
