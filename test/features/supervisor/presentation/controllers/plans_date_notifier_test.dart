import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/plans_date_notifier.dart';

// PlansDateNotifier: arranca en hoy (solo fecha, sin hora) y `select` normaliza
// cualquier DateTime a año/mes/día.

void main() {
  test('arranca en la fecha de hoy sin componente horario', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final date = container.read(plansDateProvider);
    final now = DateTime.now();

    expect(date.year, now.year);
    expect(date.month, now.month);
    expect(date.day, now.day);
    // Normalizada: sin hora/minuto/segundo.
    expect(date.hour, 0);
    expect(date.minute, 0);
    expect(date.second, 0);
    expect(date.millisecond, 0);
  });

  test('select normaliza a solo fecha (descarta la hora)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(plansDateProvider.notifier)
        .select(DateTime(2026, 7, 4, 15, 42, 10));

    expect(container.read(plansDateProvider), DateTime(2026, 7, 4));
  });

  test('select actualiza el estado a la fecha elegida', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(plansDateProvider.notifier).select(DateTime(2025, 1, 1));
    expect(container.read(plansDateProvider), DateTime(2025, 1, 1));

    container.read(plansDateProvider.notifier).select(DateTime(2025, 12, 31));
    expect(container.read(plansDateProvider), DateTime(2025, 12, 31));
  });

  group('paso de la medianoche con la app abierta', () {
    late DateTime now;
    late ProviderContainer container;

    setUp(() {
      now = DateTime(2026, 10, 20, 23, 50);
      container = ProviderContainer(
        overrides: [plansClockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
    });

    test('siguiendo a hoy, pasa al día nuevo', () {
      expect(container.read(plansDateProvider), DateTime(2026, 10, 20));

      now = DateTime(2026, 10, 21, 0, 5);
      container.read(plansDateProvider.notifier).rollOverIfNewDay();

      expect(container.read(plansDateProvider), DateTime(2026, 10, 21));
    });

    test('si el supervisor eligió otro día, se respeta', () {
      container.read(plansDateProvider.notifier).select(DateTime(2026, 10, 1));

      now = DateTime(2026, 10, 21, 0, 5);
      container.read(plansDateProvider.notifier).rollOverIfNewDay();

      expect(container.read(plansDateProvider), DateTime(2026, 10, 1));
    });

    test('elegir hoy a mano vuelve a seguir a hoy', () {
      final notifier = container.read(plansDateProvider.notifier)
        ..select(DateTime(2026, 10, 1))
        ..select(DateTime(2026, 10, 20, 9));

      now = DateTime(2026, 10, 21, 0, 5);
      notifier.rollOverIfNewDay();

      expect(container.read(plansDateProvider), DateTime(2026, 10, 21));
    });
  });
}
