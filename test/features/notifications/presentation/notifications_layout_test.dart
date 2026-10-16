import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/message_type.dart';
import 'package:logistics_app/core/api/models/notification_status.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/core/push/push_status.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:logistics_app/features/notifications/presentation/notification_detail_screen.dart';
import 'package:logistics_app/features/notifications/presentation/notifications_list_screen.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/push_status_card.dart';

import '../../../support/screen_sizes.dart';
import '../support/fake_notifications_repository.dart';
import '../support/fake_push_controller.dart';
import '../support/notification_fixtures.dart';

// Layout de la bandeja y el detalle de notificaciones en los 4 tamaños con
// letra 1.3x. Un desborde hace fallar el test solo.

Future<void> _pump(
  WidgetTester tester,
  FakeNotificationsRepository repo,
  Widget home, {
  PushStatus push = const PushStatus.idle(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo),
        pushRegistrationProvider.overrideWith(() => FakePushController(push)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => withTextScale(child!),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testOnScreens('bandeja con muchas notificaciones (1.3x)', (
    tester,
    screen,
  ) async {
    final repo = FakeNotificationsRepository()
      ..items = [
        for (var i = 0; i < 40; i++)
          notificationView(
            id: 'n$i',
            shipmentExternalId: 'EXT-2026-000$i-SANTA-CRUZ-NORTE',
            messageType: MessageType.values[i % MessageType.values.length],
            status: NotificationStatus.values[i % 3],
          ),
      ];
    await _pump(tester, repo, const NotificationsListScreen());

    expect(find.byType(PushStatusCard), findsOneWidget);
    // Lista perezosa: no se construyen las 40 filas.
    final built = find.byType(NotificationTile).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(40));

    // Se desplaza hasta el final sin desbordes.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();

    // En tablet la bandeja no se estira de borde a borde.
    final tile = tester.getRect(find.byType(NotificationTile).last);
    expect(
      tile.width,
      lessThanOrEqualTo(AppBreakpoints.maxContentWidth - 32 + 0.5),
    );
    if (screen.size.width > AppBreakpoints.maxContentWidth) {
      expect(tile.center.dx, closeTo(screen.size.width / 2, 0.5));
    }
  });

  testOnScreens('bandeja vacía con push en error (1.3x)', (
    tester,
    screen,
  ) async {
    final repo = FakeNotificationsRepository()..items = const [];
    await _pump(
      tester,
      repo,
      const NotificationsListScreen(),
      push: const PushStatus(
        state: PushRegistrationState.failed,
        message:
            'No se pudo activar las notificaciones push. Revisá los permisos '
            'del teléfono e intentá de nuevo.',
      ),
    );

    // El estado vacío se alcanza desplazando (en teléfono chico no entra).
    await tester.scrollUntilVisible(
      find.text('Sin notificaciones'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sin notificaciones'), findsOneWidget);
  });

  testOnScreens('tarjeta de push "No disponible" (1.3x)', (
    tester,
    screen,
  ) async {
    final repo = FakeNotificationsRepository()..items = const [];
    await _pump(
      tester,
      repo,
      const NotificationsListScreen(),
      push: const PushStatus(state: PushRegistrationState.unavailable),
    );

    expect(find.text('No disponible'), findsOneWidget);
    expect(find.text('Notificaciones push'), findsOneWidget);
  });

  testOnScreens('detalle con suprimir y muchos canales (1.3x)', (
    tester,
    screen,
  ) async {
    final repo = FakeNotificationsRepository()
      ..detail = notificationView(
        id: 'n1',
        shipmentExternalId: 'EXT-2026-0001-SANTA-CRUZ-NORTE-CENTRO',
        status: NotificationStatus.queued,
        attempts: const {'fcm': 3, 'email': 1},
      );
    await _pump(tester, repo, const NotificationDetailScreen(id: 'n1'));

    expect(find.text('Resumen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Suprimir notificación'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Suprimir notificación'), findsOneWidget);
    final card = tester.getRect(find.text('Resumen'));
    if (screen.size.width > AppBreakpoints.maxContentWidth) {
      // Contenido centrado y acotado a maxContentWidth.
      final left = (screen.size.width - AppBreakpoints.maxContentWidth) / 2;
      expect(card.left, greaterThanOrEqualTo(left));
    }
  });
}
