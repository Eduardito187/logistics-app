import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/connectivity_notifier.dart';
import 'package:logistics_app/core/offline/sync_queue_provider.dart';
import 'package:logistics_app/features/home/presentation/role_home_screen.dart';
import 'package:logistics_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:logistics_app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/supervisor_controllers.dart';

import '../../notifications/support/fake_notifications_repository.dart';
import '../../supervisor/support/fake_supervisor_repository.dart';

// Precarga del inicio (HomePrefetcher real): al entrar el supervisor se piden en
// segundo plano tablero (con los planes del día), placas, alertas y la bandeja;
// quedan en caché corta para el primer toque y después se liberan.

class _FakeConnectivity extends ConnectivityNotifier {
  @override
  Future<bool> build() async => true;
}

void main() {
  testWidgets('supervisor: precarga tablero, placas, alertas y bandeja', (
    tester,
  ) async {
    final supervisor = FakeSupervisorRepository();
    final notifications = FakeNotificationsRepository();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        featureTasksProvider.overrideWithValue(const []),
        syncQueueProvider.overrideWith(
          (ref) => Stream<List<OutboxAction>>.value(const []),
        ),
        connectivityProvider.overrideWith(_FakeConnectivity.new),
        supervisorRepositoryProvider.overrideWithValue(supervisor),
        notificationsRepositoryProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).devSignIn(UserRole.supervisor);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoleHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(supervisor.shipmentsCalls, 1); // tablero
    expect(supervisor.plansCalls, 1); // planes del día (compartidos)
    expect(supervisor.platesCalls, 1);
    expect(supervisor.listAlertsCalls, 2); // tablero (abiertas) + Alertas
    expect(notifications.requestedLimits, hasLength(1));
    // Sin spinner nuevo en el inicio.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Lo precargado sigue disponible para el primer toque...
    expect(container.exists(dashboardMetricsProvider), isTrue);
    expect(container.exists(notificationsListProvider), isTrue);

    // ...y pasado el plazo de la caché corta se libera (no queda retenido por
    // el inicio, que vive toda la sesión).
    await tester.pump(const Duration(seconds: 61));
    await tester.pump();
    expect(container.exists(dashboardMetricsProvider), isFalse);
    expect(container.exists(notificationsListProvider), isFalse);
  });
}
