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
}
