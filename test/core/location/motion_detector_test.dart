import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/motion_detector.dart';

// GPS adaptativo (batería): detector en marcha / detenido y perfiles del
// rastreo del camión.

const _a = GpsFix(lat: -17.7800, lng: -63.1800, accuracy: 10);
// ~6 m de _a (jitter de GPS estando parado).
const _aJitter = GpsFix(lat: -17.78005, lng: -63.18003, accuracy: 10);
// ~110 m al norte de _a.
const _b = GpsFix(lat: -17.7790, lng: -63.1800, accuracy: 10);

void main() {
  final t0 = DateTime(2026, 11, 11, 9);

  group('MotionDetector', () {
    test('distancia por semiverseno (~111 m por milésima de grado)', () {
      final d = MotionDetector.distanceMeters(_a, _b);
      expect(d, closeTo(111, 2));
      expect(MotionDetector.distanceMeters(_a, _a), 0);
    });

    test('arranca "en marcha" y pasa a detenido tras 3 min quieto', () {
      final m = MotionDetector();
      expect(m.motion, TruckMotion.moving);
      expect(m.onFix(_a, t0), isFalse);
      expect(
        m.onFix(_aJitter, t0.add(const Duration(minutes: 1))),
        isFalse,
      );
      expect(m.timeUntilStill(t0.add(const Duration(minutes: 1))),
          const Duration(minutes: 2));
      expect(m.evaluate(t0.add(const Duration(minutes: 3))), isTrue);
      expect(m.motion, TruckMotion.stationary);
      expect(m.timeUntilStill(t0.add(const Duration(minutes: 4))), isNull);
    });

    test('el jitter dentro del radio no reinicia el reloj de quietud', () {
      final m = MotionDetector();
      m.onFix(_a, t0);
      m.onFix(_aJitter, t0.add(const Duration(minutes: 2)));
      expect(m.onFix(_aJitter, t0.add(const Duration(minutes: 3))), isTrue);
      expect(m.motion, TruckMotion.stationary);
    });

    test('moverse más del radio vuelve a "en marcha"', () {
      final m = MotionDetector();
      m.onFix(_a, t0);
      m.evaluate(t0.add(const Duration(minutes: 5)));
      expect(m.motion, TruckMotion.stationary);
      expect(m.onFix(_b, t0.add(const Duration(minutes: 6))), isTrue);
      expect(m.motion, TruckMotion.moving);
    });

    test('una lectura imprecisa agranda el radio (no cuenta como marcha)', () {
      final m = MotionDetector();
      m.onFix(_a, t0);
      m.evaluate(t0.add(const Duration(minutes: 5)));
      // ~110 m pero con precisión de 150 m: no es movimiento confiable.
      const vague = GpsFix(lat: -17.7790, lng: -63.1800, accuracy: 150);
      expect(m.onFix(vague, t0.add(const Duration(minutes: 6))), isFalse);
      expect(m.motion, TruckMotion.stationary);
    });

    test('reset vuelve a "en marcha" sin ancla', () {
      final m = MotionDetector();
      m.onFix(_a, t0);
      m.evaluate(t0.add(const Duration(minutes: 5)));
      m.reset();
      expect(m.motion, TruckMotion.moving);
      expect(m.timeUntilStill(t0), isNull);
    });
  });

  group('TrackingProfile', () {
    test('resolve elige por movimiento y energía', () {
      expect(
        TrackingProfile.resolve(motion: TruckMotion.moving, saveEnergy: false),
        TrackingProfile.moving,
      );
      expect(
        TrackingProfile.resolve(motion: TruckMotion.moving, saveEnergy: true),
        TrackingProfile.movingSaving,
      );
      expect(
        TrackingProfile.resolve(
          motion: TruckMotion.stationary,
          saveEnergy: false,
        ),
        TrackingProfile.stationary,
      );
      expect(
        TrackingProfile.resolve(
          motion: TruckMotion.stationary,
          saveEnergy: true,
        ),
        TrackingProfile.stationarySaving,
      );
    });

    test('detenido no prende el chip GPS y espacia lecturas y envíos', () {
      expect(TrackingProfile.stationary.accuracy, LocationAccuracy.medium);
      expect(TrackingProfile.stationarySaving.accuracy, LocationAccuracy.low);
      expect(
        TrackingProfile.stationary.interval,
        greaterThan(TrackingProfile.moving.interval),
      );
    });

    test('ahorro de energía duplica intervalos', () {
      expect(
        TrackingProfile.movingSaving.interval,
        TrackingProfile.moving.interval * 2,
      );
      expect(
        TrackingProfile.movingSaving.flushInterval,
        TrackingProfile.moving.flushInterval * 2,
      );
    });

    test('envío por lotes: en marcha cada 60 s (no un POST por lectura)', () {
      expect(TrackingProfile.moving.flushInterval, const Duration(seconds: 60));
      expect(
        TrackingProfile.moving.flushInterval,
        greaterThan(TrackingProfile.moving.minEnqueueInterval),
      );
    });

    test('Android: perfil en marcha sin filtro de distancia, intervalo 15 s', () {
      final s = LocationService.settingsForProfile(
        TrackingProfile.moving,
        platform: TargetPlatform.android,
      );
      expect(s, isA<AndroidSettings>());
      final android = s as AndroidSettings;
      expect(android.distanceFilter, 0);
      expect(android.intervalDuration, const Duration(seconds: 15));
      expect(android.accuracy, LocationAccuracy.high);
    });

    test('Android: detenido → precisión media, 50 m, 60 s', () {
      final s =
          LocationService.settingsForProfile(
                TrackingProfile.stationary,
                platform: TargetPlatform.android,
              )
              as AndroidSettings;
      expect(s.accuracy, LocationAccuracy.medium);
      expect(s.distanceFilter, 50);
      expect(s.intervalDuration, const Duration(seconds: 60));
    });

    test('iOS: siempre con filtro de distancia (iOS ignora el intervalo)', () {
      for (final p in [
        TrackingProfile.moving,
        TrackingProfile.movingSaving,
        TrackingProfile.stationary,
        TrackingProfile.stationarySaving,
      ]) {
        final s = LocationService.settingsForProfile(
          p,
          platform: TargetPlatform.iOS,
        );
        expect(s, isA<AppleSettings>());
        expect(s.distanceFilter, greaterThanOrEqualTo(25), reason: '$p');
        expect(s.accuracy, p.accuracy);
      }
    });
  });
}
