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
}
