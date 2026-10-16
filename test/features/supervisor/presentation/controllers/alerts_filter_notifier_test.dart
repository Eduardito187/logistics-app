import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/alerts_filter_notifier.dart';

// AlertsFilterNotifier: arranca mostrando solo las alertas sin reconocer (true) y
// permite alternar a "todas" (false).

void main() {
  test('por defecto muestra solo las alertas sin reconocer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(alertsFilterProvider), isTrue);
  });

  test('setUnacknowledgedOnly(false) cambia a mostrar todas', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(alertsFilterProvider.notifier)
        .setUnacknowledgedOnly(value: false);
    expect(container.read(alertsFilterProvider), isFalse);

    container
        .read(alertsFilterProvider.notifier)
        .setUnacknowledgedOnly(value: true);
    expect(container.read(alertsFilterProvider), isTrue);
  });
}
