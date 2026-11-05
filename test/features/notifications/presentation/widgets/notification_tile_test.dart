import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/api/models/message_type.dart';
import 'package:logistics_app/core/api/models/notification_status.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/notification_tile.dart';

import '../../../../support/app_icon_finders.dart';
import '../../support/notification_fixtures.dart';

// NotificationTile: tipo de mensaje, envío de referencia (external id si existe,
// si no el shipment id) y pastilla de estado. Al tocarla navega al detalle.

GoRouter _router(Widget tile) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => Scaffold(body: tile),
    ),
    GoRoute(
      path: '/notifications/:id',
      builder: (_, state) =>
          Scaffold(body: Text('detalle ${state.pathParameters['id']}')),
    ),
  ],
);

void main() {
  testWidgets('muestra tipo, referencia externa y estado', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: _router(
          NotificationTile(
            notification: notificationView(
              shipmentId: 'SHP-INTERNAL',
              shipmentExternalId: 'EXT-9',
              messageType: MessageType.enRoute,
              status: NotificationStatus.queued,
            ),
          ),
        ),
      ),
    );

    expect(find.text('En ruta'), findsOneWidget); // tipo
    expect(find.text('Envío EXT-9'), findsOneWidget); // prefiere la externa
    expect(find.text('En cola'), findsOneWidget); // pastilla de estado
    expect(findAppIcon(AppIcon.chevronRight), findsOneWidget);
  });

  testWidgets('sin referencia externa muestra solo "Envío" (nunca el uuid)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: _router(
          NotificationTile(notification: notificationView(shipmentId: 'SHP-7')),
        ),
      ),
    );

    expect(find.text('Envío'), findsOneWidget);
    // El id/uuid del envío nunca se muestra al usuario.
    expect(find.textContaining('SHP-7'), findsNothing);
  });

  testWidgets('al tocarla navega al detalle de la notificación', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: _router(
          NotificationTile(notification: notificationView(id: 'n-42')),
        ),
      ),
    );

    await tester.tap(find.byType(NotificationTile));
    await tester.pumpAndSettle();

    expect(find.text('detalle n-42'), findsOneWidget);
  });
}
