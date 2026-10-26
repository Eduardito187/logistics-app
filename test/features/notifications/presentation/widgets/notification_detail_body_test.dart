import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/channel.dart';
import 'package:logistics_app/core/api/models/message_type.dart';
import 'package:logistics_app/core/api/models/notification_status.dart';
import 'package:logistics_app/core/api/models/notification_view.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/notification_detail_body.dart';

import '../../support/notification_fixtures.dart';

// NotificationDetailBody: resumen + cascada de canales con intentos + botón de
// suprimir (solo si la notificación está en cola).

Future<void> _pump(
  WidgetTester tester, {
  required NotificationView notification,
  bool suppressing = false,
  Future<void> Function()? onSuppress,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NotificationDetailBody(
          notification: notification,
          suppressing: suppressing,
          onSuppress: onSuppress ?? () async {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra resumen y cascada de canales con intentos', (
    tester,
  ) async {
    await _pump(
      tester,
      notification: notificationView(
        shipmentExternalId: 'EXT-1',
        messageType: MessageType.enRoute,
        status: NotificationStatus.queued,
        currentChannel: Channel.telegram,
        channels: const [Channel.fcm, Channel.email],
        attempts: const {'FCM': 2},
      ),
    );

    // Resumen.
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('En ruta'), findsOneWidget); // tipo
    expect(find.text('En cola'), findsOneWidget); // estado (pastilla)
    expect(find.text('EXT-1'), findsOneWidget); // envío de referencia
    expect(find.text('Telegram'), findsOneWidget); // canal actual
    // Cascada: push con 2 intentos, email con 0 (ausente en el mapa → 0).
    expect(find.text('Cascada de canales'), findsOneWidget);
    expect(find.text('Push (Firebase)'), findsOneWidget);
    expect(find.text('2 intento(s)'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('0 intento(s)'), findsOneWidget);
  });

  testWidgets('en cola muestra el botón de suprimir y dispara el callback', (
    tester,
  ) async {
    var called = 0;
    await _pump(
      tester,
      notification: notificationView(status: NotificationStatus.queued),
      onSuppress: () async => called++,
    );

    final button = find.text('Suprimir notificación');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();
    expect(called, 1);
  });

  testWidgets('si no está en cola, no muestra el botón de suprimir', (
    tester,
  ) async {
    await _pump(
      tester,
      notification: notificationView(status: NotificationStatus.sent),
    );

    expect(find.text('Suprimir notificación'), findsNothing);
  });

  testWidgets('suprimiendo deshabilita el botón y muestra el spinner', (
    tester,
  ) async {
    var called = 0;
    await _pump(
      tester,
      notification: notificationView(status: NotificationStatus.queued),
      suppressing: true,
      onSuppress: () async => called++,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // El botón está deshabilitado: tocarlo no llama al callback.
    await tester.tap(find.text('Suprimir notificación'));
    await tester.pump();
    expect(called, 0);
  });

  testWidgets('sin canales configurados muestra el texto correspondiente', (
    tester,
  ) async {
    await _pump(tester, notification: notificationView(channels: const []));

    expect(find.text('Sin canales configurados.'), findsOneWidget);
  });
}
