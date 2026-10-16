import 'package:go_router/go_router.dart';

import 'notification_detail_screen.dart';
import 'notifications_list_screen.dart';

/// Rutas del feature de notificaciones, para enchufar en el router global.
final List<RouteBase> notificationsRoutes = [
  GoRoute(
    path: '/notifications',
    builder: (context, state) => const NotificationsListScreen(),
  ),
  GoRoute(
    path: '/notifications/:id',
    builder: (context, state) =>
        NotificationDetailScreen(id: state.pathParameters['id']!),
  ),
];
