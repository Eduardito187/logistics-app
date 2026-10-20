import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/background/sync_scheduler.dart';

void main() {
  test('sin initBackgroundSync el planificador es no-op', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final scheduler = container.read(syncSchedulerProvider);
    expect(scheduler, isA<NoopSyncScheduler>());
    await scheduler.scheduleOneOff();
  });

  test('el provider usa el planificador registrado', () {
    final previous = BackgroundSyncRegistry.scheduler;
    addTearDown(() => BackgroundSyncRegistry.scheduler = previous);
    final custom = _Custom();
    BackgroundSyncRegistry.scheduler = custom;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(syncSchedulerProvider), same(custom));
  });

  test('identificadores estables y frecuencia mínima de Android', () {
    expect(BackgroundSyncTasks.periodic, 'bo.com.dismac.logisticsApp.sync');
    expect(BackgroundSyncTasks.oneOff, isNot(BackgroundSyncTasks.periodic));
    expect(
      BackgroundSyncTasks.frequency,
      greaterThanOrEqualTo(const Duration(minutes: 15)),
    );
  });
}

class _Custom implements SyncScheduler {
  @override
  Future<void> scheduleOneOff() async {}
}
