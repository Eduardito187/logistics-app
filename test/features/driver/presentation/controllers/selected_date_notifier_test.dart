import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';

// Fecha seleccionada de la ruta: siempre normalizada a medianoche.

void main() {
  test('el valor inicial es hoy a medianoche', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final value = container.read(selectedDateProvider);
    expect(value.hour, 0);
    expect(value.minute, 0);
    expect(value.second, 0);
    final now = DateTime.now();
    expect(value, DateTime(now.year, now.month, now.day));
  });

  test('select normaliza a medianoche descartando la hora', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(selectedDateProvider.notifier)
        .select(DateTime(2026, 7, 4, 15, 30, 59));

    expect(container.read(selectedDateProvider), DateTime(2026, 7, 4));
  });
}
