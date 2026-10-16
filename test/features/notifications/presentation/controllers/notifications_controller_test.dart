import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:logistics_app/features/notifications/domain/usecases/suppress_notification.dart';
import 'package:logistics_app/features/notifications/presentation/controllers/notifications_controller.dart';

import '../../support/fake_notifications_repository.dart';
import '../../support/notification_fixtures.dart';

// Providers de notificaciones: lista y detalle delegan en los casos de uso y
// propagan el error; el command de supresión llega al repositorio.

ProviderContainer _container(FakeNotificationsRepository repo) {
  final container = ProviderContainer(
    // Sin reintentos: un provider que falla debe asentarse en AsyncError para
    // poder esperar el error desde `.future` (Riverpod reintenta por defecto).
    retry: (_, _) => null,
    overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('notificationsListProvider devuelve la lista del repositorio', () async {
    final repo = FakeNotificationsRepository()
      ..items = [notificationView(id: 'n1'), notificationView(id: 'n2')];
    final container = _container(repo);
    container.listen(notificationsListProvider, (_, _) {});

    final value = await container.read(notificationsListProvider.future);
    expect(value, hasLength(2));
  });

  test('notificationsListProvider propaga el ApiException', () async {
    final repo = FakeNotificationsRepository()
      ..listError = const ApiException(status: 500, title: 'x');
    final container = _container(repo);
    container.listen(notificationsListProvider, (_, _) {});

    await expectLater(
      container.read(notificationsListProvider.future),
      throwsA(isA<ApiException>()),
    );
  });

  test('notificationDetailProvider devuelve el detalle por id', () async {
    final repo = FakeNotificationsRepository()
      ..detail = notificationView(id: 'n9');
    final container = _container(repo);
    container.listen(notificationDetailProvider('n9'), (_, _) {});

    final value = await container.read(notificationDetailProvider('n9').future);
    expect(value.id, 'n9');
  });

  test('suppressNotification delega en el repositorio', () async {
    final repo = FakeNotificationsRepository();
    final container = _container(repo);

    await container.read(suppressNotificationProvider).call('n5');
    expect(repo.suppressedIds, ['n5']);
  });
}
