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

  group('paginación (notificationsLimitProvider)', () {
    test('pide la primera página y "showMore" pide una más', () async {
      final repo = FakeNotificationsRepository()
        ..items = [notificationView(id: 'n1')];
      final container = _container(repo);
      container.listen(notificationsListProvider, (_, _) {});

      await container.read(notificationsListProvider.future);
      expect(repo.requestedLimits.last, notificationsPageSize);

      container.read(notificationsLimitProvider.notifier).showMore();
      await container.read(notificationsListProvider.future);
      expect(repo.requestedLimits.last, notificationsPageSize * 2);
    });

    test('nunca pasa del tope en memoria', () {
      final repo = FakeNotificationsRepository();
      final container = _container(repo);
      container.listen(notificationsLimitProvider, (_, _) {});
      final notifier = container.read(notificationsLimitProvider.notifier);
      for (var i = 0; i < 20; i++) {
        notifier.showMore();
      }
      expect(container.read(notificationsLimitProvider), notificationsMaxLimit);
      expect(notifier.canShowMore, isFalse);
    });

    test('si el backend manda de más, recorta al límite', () async {
      final repo = FakeNotificationsRepository()
        ..items = [
          for (var i = 0; i < notificationsPageSize + 10; i++)
            notificationView(id: 'n$i'),
        ];
      final container = _container(repo);
      container.listen(notificationsListProvider, (_, _) {});

      final value = await container.read(notificationsListProvider.future);
      expect(value, hasLength(notificationsPageSize));
      expect(value.first.id, 'n0');
    });
  });

  group('caché y detalle desde la lista', () {
    test(
      'el detalle usa la notificación de la lista sin pedirla por id',
      () async {
        final repo = FakeNotificationsRepository()
          ..items = [notificationView(id: 'n1', shipmentExternalId: 'EXT-1')];
        final container = _container(repo);
        container.listen(notificationsListProvider, (_, _) {});
        await container.read(notificationsListProvider.future);

        container.listen(notificationDetailProvider('n1'), (_, _) {});
        final detail = await container.read(
          notificationDetailProvider('n1').future,
        );

        expect(detail.shipmentExternalId, 'EXT-1');
        expect(repo.getCalls, 0);
      },
    );

    test('sin lista cargada (p. ej. desde un push) pide por id', () async {
      final repo = FakeNotificationsRepository()
        ..detail = notificationView(id: 'n7');
      final container = _container(repo);
      container.listen(notificationDetailProvider('n7'), (_, _) {});

      final detail = await container.read(
        notificationDetailProvider('n7').future,
      );

      expect(detail.id, 'n7');
      expect(repo.getCalls, 1);
      // Mirar el detalle no dispara la lista.
      expect(repo.requestedLimits, isEmpty);
    });

    test(
      'volver a abrir la bandeja dentro del plazo no repite el GET',
      () async {
        final repo = FakeNotificationsRepository()
          ..items = [notificationView()];
        final container = _container(repo);

        final first = container.listen(notificationsListProvider, (_, _) {});
        await container.read(notificationsListProvider.future);
        first.close(); // sale de la bandeja
        await Future<void>.delayed(Duration.zero);

        container.listen(notificationsListProvider, (_, _) {});
        await container.read(notificationsListProvider.future);

        expect(repo.requestedLimits, hasLength(1));
      },
    );
  });
}
