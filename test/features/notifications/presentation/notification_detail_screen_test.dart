import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/notification_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:logistics_app/features/notifications/presentation/notification_detail_screen.dart';

import '../support/fake_notifications_repository.dart';
import '../support/notification_fixtures.dart';

// NotificationDetailScreen: detalle (datos/error) y acción de suprimir una
// notificación en cola (éxito → SnackBar verde; fallo → SnackBar rojo).

Future<void> _pump(
  WidgetTester tester,
  FakeNotificationsRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NotificationDetailScreen(id: 'n1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos muestra el detalle', (tester) async {
    final repo = FakeNotificationsRepository()
      ..detail = notificationView(
        id: 'n1',
        shipmentExternalId: 'EXT-1',
        status: NotificationStatus.queued,
      );
    await _pump(tester, repo);

    expect(find.text('Notificación'), findsOneWidget); // AppBar
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('EXT-1'), findsOneWidget);
    expect(find.text('Suprimir notificación'), findsOneWidget); // en cola
  });

  testWidgets('en error muestra el estado de error con reintento', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository()
      ..detailError = const ApiException(status: 500, title: 'x');
    await _pump(tester, repo);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('suprimir OK llama al repositorio y muestra SnackBar de éxito', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository()
      ..detail = notificationView(id: 'n1', status: NotificationStatus.queued);
    await _pump(tester, repo);

    await tester.tap(find.text('Suprimir notificación'));
    await tester.pump(); // estado suprimiendo
    await tester.pumpAndSettle();

    expect(repo.suppressedIds, ['n1']);
    expect(find.text('Notificación suprimida.'), findsOneWidget);
  });

  testWidgets('suprimir con error muestra un SnackBar de error', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository()
      ..detail = notificationView(id: 'n1', status: NotificationStatus.queued)
      ..suppressError = const ApiException(status: 500, title: 'x');
    await _pump(tester, repo);

    await tester.tap(find.text('Suprimir notificación'));
    await tester.pump();
    await tester.pump();

    expect(repo.suppressedIds, isEmpty);
    expect(
      find.text('Error del servidor. Probá de nuevo en un momento.'),
      findsOneWidget,
    );
  });
}
