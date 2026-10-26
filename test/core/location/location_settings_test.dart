import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logistics_app/core/location/location_service.dart';

// Ajustes del flujo de GPS: en Android se pide intervalo mínimo además del
// filtro de distancia (batería, CPU y filas en la cola en gama baja).
void main() {
  test('Android: AndroidSettings con intervalo y filtro de distancia', () {
    final settings = LocationService.streamSettings(
      distanceFilterMeters: 20,
      platform: TargetPlatform.android,
    );
    expect(settings, isA<AndroidSettings>());
    final android = settings as AndroidSettings;
    expect(android.intervalDuration, LocationService.streamInterval);
    expect(android.distanceFilter, 20);
    expect(android.accuracy, LocationAccuracy.high);
  });

  test('el intervalo es de 10 s', () {
    expect(LocationService.streamInterval, const Duration(seconds: 10));
  });

  test('otras plataformas: LocationSettings genérico con el filtro', () {
    final settings = LocationService.streamSettings(
      distanceFilterMeters: 35,
      platform: TargetPlatform.iOS,
    );
    expect(settings, isNot(isA<AndroidSettings>()));
    expect(settings.distanceFilter, 35);
  });

  test('iOS: navegación de vehículo, sin pausa automática y en 2.º plano', () {
    final settings = LocationService.streamSettings(
      distanceFilterMeters: 20,
      platform: TargetPlatform.iOS,
    );
    expect(settings, isA<AppleSettings>());
    final apple = settings as AppleSettings;
    expect(apple.activityType, ActivityType.automotiveNavigation);
    expect(apple.pauseLocationUpdatesAutomatically, isFalse);
    expect(apple.allowBackgroundLocationUpdates, isTrue);
    expect(apple.accuracy, LocationAccuracy.high);
  });

  test('sin ruta activa: precisión balanceada (menos batería)', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      final settings = LocationService.streamSettings(
        distanceFilterMeters: 20,
        platform: platform,
        highAccuracy: false,
      );
      expect(settings.accuracy, LocationAccuracy.medium);
    }
  });

  group('isFreshEnough (reusar la última posición)', () {
    final now = DateTime(2026, 10, 19, 12);
    Position pos({required Duration age, double accuracy = 10}) => Position(
      longitude: -68.1,
      latitude: -16.5,
      timestamp: now.subtract(age),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    test('reciente y precisa: se reusa', () {
      expect(
        LocationService.isFreshEnough(
          pos(age: const Duration(seconds: 5)),
          now: now,
        ),
        isTrue,
      );
    });

    test('de hace 2 min: se reusa (tope 5 min)', () {
      expect(
        LocationService.isFreshEnough(
          pos(age: const Duration(minutes: 2)),
          now: now,
        ),
        isTrue,
      );
    });

    test('vieja (> 5 min): se pide una lectura nueva', () {
      expect(
        LocationService.isFreshEnough(
          pos(age: const Duration(minutes: 6)),
          now: now,
        ),
        isFalse,
      );
    });

    test('imprecisa: se pide una lectura nueva', () {
      expect(
        LocationService.isFreshEnough(
          pos(age: const Duration(seconds: 5), accuracy: 300),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
