import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';

// Rastreo del camión (Notifier). Las rutas que levantan el foreground service
// (start exitoso, re-apuntar, stop, _onFix) dependen del plugin
// flutter_foreground_task vía MethodChannel y pertenecen a pruebas de
// integración en dispositivo. Aquí se cubre lo que NO toca la plataforma:
// el estado inicial y el corte temprano por falta de permiso.

class _FakeLocationService extends LocationService {
  bool background = true;
  @override
  Future<bool> ensureBackgroundPermission() async => background;
}

ProviderContainer _container(_FakeLocationService location) {
  final container = ProviderContainer(
    overrides: [locationServiceProvider.overrideWithValue(location)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('estado inicial: inactivo, sin envío, 0 enviados', () {
    final container = _container(_FakeLocationService());
    final state = container.read(truckTrackingProvider);
    expect(state.active, isFalse);
    expect(state.shipmentId, isNull);
    expect(state.sent, 0);
    expect(state.lastFix, isNull);
  });

  test(
    'start devuelve false y no activa si falta el permiso "siempre"',
    () async {
      final location = _FakeLocationService()..background = false;
      final container = _container(location);

      final ok = await container
          .read(truckTrackingProvider.notifier)
          .start(shipmentId: 'SHP-1');

      expect(ok, isFalse);
      final state = container.read(truckTrackingProvider);
      expect(state.active, isFalse);
      expect(state.shipmentId, isNull);
    },
  );
}
