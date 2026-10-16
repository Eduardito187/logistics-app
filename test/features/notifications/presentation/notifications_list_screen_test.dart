import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/message_type.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/core/push/push_status.dart';
import 'package:logistics_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:logistics_app/features/notifications/presentation/notifications_list_screen.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/push_status_card.dart';

import '../support/fake_notifications_repository.dart';
import '../support/fake_push_controller.dart';
import '../support/notification_fixtures.dart';

// NotificationsListScreen: tarjeta de estado push + bandeja (datos, vacía, error).
// El push se sustituye por un controlador falso para no arrancar el plumbing real.

Future<void> _pump(
  WidgetTester tester,
  FakeNotificationsRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo),
        pushRegistrationProvider.overrideWith(
          () => FakePushController(const PushStatus.idle()),
        ),
      ],
      child: const MaterialApp(home: NotificationsListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos muestra la tarjeta de push y la lista', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository()
      ..items = [
        notificationView(id: 'n1', messageType: MessageType.enRoute),
        notificationView(id: 'n2', messageType: MessageType.delivered),
      ];
    await _pump(tester, repo);

    expect(find.text('Notificaciones'), findsOneWidget); // AppBar
    expect(find.byType(PushStatusCard), findsOneWidget);
    expect(find.byType(NotificationTile), findsNWidgets(2));
    expect(find.text('En ruta'), findsOneWidget);
    expect(find.text('Entregado'), findsOneWidget);
  });

  testWidgets('bandeja vacía muestra el estado vacío', (tester) async {
    final repo = FakeNotificationsRepository()..items = const [];
    await _pump(tester, repo);

    expect(find.text('Sin notificaciones'), findsOneWidget);
    expect(
      find.text('No hay notificaciones en la operación por ahora.'),
      findsOneWidget,
    );
    // La tarjeta de push sigue visible aunque no haya notificaciones.
    expect(find.byType(PushStatusCard), findsOneWidget);
  });

  testWidgets('en error muestra el estado de error con reintento', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository()
      ..listError = const ApiException(status: 500, title: 'x');
    await _pump(tester, repo);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
