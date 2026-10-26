// Se importan las PlatformInterface (transitivas) para sustituir los plugins en
// test; es la forma soportada de mockearlos sin plataforma real.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async' show Completer;

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// LocationService es un wrapper fino sobre geolocator (permiso + GPS) y
// permission_handler (permiso "siempre"). Se mockean ambos a través de su
// PlatformInterface, que es la forma soportada de sustituir el plugin en tests
// sin tocar la plataforma real.

class _FakeGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.always;
  LocationPermission requested = LocationPermission.always;
  Position? position;
  Object? positionError;
  List<Position> streamPositions = const [];

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => requested;

  Position? lastKnown;
  int currentCalls = 0;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnown;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    currentCalls++;
    if (positionError != null) throw positionError!;
    return position!;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      Stream<Position>.fromIterable(streamPositions);
}

class _FakePermissions extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  PermissionStatus alwaysStatus = PermissionStatus.granted;
  PermissionStatus alwaysRequestResult = PermissionStatus.granted;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      alwaysStatus;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async => {for (final p in permissions) p: alwaysRequestResult};

  @override
  Future<bool> openAppSettings() async => true;
}

Position _pos(double lat, double lng, double acc) => Position(
  longitude: lng,
  latitude: lat,
  timestamp: DateTime(2024, 1, 1),
  accuracy: acc,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _FakeGeolocator geo;
  late _FakePermissions perms;
  late LocationService service;

  setUp(() {
    geo = _FakeGeolocator();
    perms = _FakePermissions();
    GeolocatorPlatform.instance = geo;
    PermissionHandlerPlatform.instance = perms;
    service = LocationService();
  });

  group('ensurePermission', () {
    test('false si el servicio de ubicación está apagado', () async {
      geo.serviceEnabled = false;
      expect(await service.ensurePermission(), isFalse);
    });

    test('true si ya está concedido "always"', () async {
      geo.permission = LocationPermission.always;
      expect(await service.ensurePermission(), isTrue);
    });

    test('true si está concedido "whileInUse"', () async {
      geo.permission = LocationPermission.whileInUse;
      expect(await service.ensurePermission(), isTrue);
    });

    test('pide permiso cuando está "denied" y acepta si lo conceden', () async {
      geo.permission = LocationPermission.denied;
      geo.requested = LocationPermission.whileInUse;
      expect(await service.ensurePermission(), isTrue);
    });

    test('false si tras pedirlo sigue denegado', () async {
      geo.permission = LocationPermission.denied;
      geo.requested = LocationPermission.denied;
      expect(await service.ensurePermission(), isFalse);
    });

    test('false si está "deniedForever" (no se vuelve a pedir)', () async {
      geo.permission = LocationPermission.deniedForever;
      expect(await service.ensurePermission(), isFalse);
    });
  });

  group('ensureBackgroundPermission', () {
    test('false si falta el permiso de primer plano (corta antes)', () async {
      geo.serviceEnabled = false;
      expect(await service.ensureBackgroundPermission(), isFalse);
    });

    test('true si "always" ya está concedido sin volver a pedir', () async {
      perms.alwaysStatus = PermissionStatus.granted;
      perms.alwaysRequestResult = PermissionStatus.denied; // no debería usarse
      expect(await service.ensureBackgroundPermission(), isTrue);
    });

    test('pide "always" cuando no está y acepta si lo conceden', () async {
      perms.alwaysStatus = PermissionStatus.denied;
      perms.alwaysRequestResult = PermissionStatus.granted;
      expect(await service.ensureBackgroundPermission(), isTrue);
    });

    test('false si el usuario niega "always"', () async {
      perms.alwaysStatus = PermissionStatus.denied;
      perms.alwaysRequestResult = PermissionStatus.permanentlyDenied;
      expect(await service.ensureBackgroundPermission(), isFalse);
    });
  });

  group('current', () {
    test('null si no hay permiso', () async {
      geo.serviceEnabled = false;
      expect(await service.current(), isNull);
    });

    test('devuelve GpsFix con la posición actual', () async {
      geo.position = _pos(-16.5, -68.15, 5);
      final fix = await service.current();
      expect(fix, isNotNull);
      expect(fix!.lat, -16.5);
      expect(fix.lng, -68.15);
      expect(fix.accuracy, 5);
    });

    test('null (no lanza) si el GPS agota tiempo o falla', () async {
      geo.positionError = TimeoutException('sin fix a tiempo');
      expect(await service.current(), isNull);
    });
  });

  group('stream', () {
    test('mapea cada Position a un GpsFix', () async {
      geo.streamPositions = [_pos(1, 2, 3), _pos(4, 5, 6)];
      final fixes = await service.stream().toList();
      expect(fixes, hasLength(2));
      expect(fixes.first.lat, 1);
      expect(fixes.first.lng, 2);
      expect(fixes.first.accuracy, 3);
      expect(fixes.last.lat, 4);
    });
  });
  group('current reusa la última posición reciente (batería)', () {
    Position fresh({Duration age = Duration.zero, double accuracy = 8}) =>
        Position(
          longitude: -68.1,
          latitude: -16.5,
          timestamp: DateTime.now().subtract(age),
          accuracy: accuracy,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

    test('última posición fresca y precisa: no prende el GPS', () async {
      geo.lastKnown = fresh(age: const Duration(seconds: 3));
      final fix = await service.current();
      expect(fix?.lat, -16.5);
      expect(geo.currentCalls, 0);
    });

    test('última posición vieja: pide una lectura nueva', () async {
      geo.lastKnown = fresh(age: const Duration(minutes: 10));
      geo.position = _pos(1, 2, 5);
      final fix = await service.current();
      expect(fix?.lat, 1);
      expect(geo.currentCalls, 1);
    });

    test(
      'hasta 5 min y 200 m sirve (andén/tienda: el lugar no cambia)',
      () async {
        geo.lastKnown = fresh(age: const Duration(minutes: 4), accuracy: 150);
        final fix = await service.current();
        expect(fix?.lat, -16.5);
        expect(geo.currentCalls, 0);
      },
    );

    test('imprecisa (> 200 m): pide una lectura nueva', () async {
      geo.lastKnown = fresh(age: const Duration(seconds: 3), accuracy: 500);
      geo.position = _pos(1, 2, 5);
      expect((await service.current())?.lat, 1);
      expect(geo.currentCalls, 1);
    });
  });

  group('current nunca bloquea (regla 4)', () {
    test(
      'GPS colgado: devuelve en ≤ 1,5 s la última aunque sea vieja',
      () async {
        final slow = _SlowGeolocator()
          ..lastKnown = _pos(-16.4, -68.1, 30); // de 2024: vieja
        GeolocatorPlatform.instance = slow;
        final watch = Stopwatch()..start();
        final fix = await service.current();
        watch.stop();
        expect(fix?.lat, -16.4);
        expect(
          watch.elapsed,
          lessThan(
            LocationService.currentMaxWait + const Duration(milliseconds: 500),
          ),
        );
        slow.release(_pos(1, 2, 5));
      },
    );

    test('GPS colgado y sin ninguna posición: null a tiempo', () async {
      final slow = _SlowGeolocator();
      GeolocatorPlatform.instance = slow;
      final fix = await service.current(
        timeout: const Duration(milliseconds: 100),
      );
      expect(fix, isNull);
      slow.release(_pos(1, 2, 5));
    });

    test('la lectura que no llegó a tiempo calienta el siguiente', () async {
      final slow = _SlowGeolocator();
      GeolocatorPlatform.instance = slow;
      expect(
        await service.current(timeout: const Duration(milliseconds: 50)),
        isNull,
      );
      slow.release(_pos(-16.6, -68.2, 8));
      await Future<void>.delayed(Duration.zero);
      final fix = await service.current();
      expect(fix?.lat, -16.6);
      // Una sola lectura al GPS: la segunda llamada usó la caché.
      expect(slow.currentCalls, 1);
    });

    test('timeout mayor al tope se recorta a currentMaxWait', () async {
      final slow = _SlowGeolocator();
      GeolocatorPlatform.instance = slow;
      final watch = Stopwatch()..start();
      await service.current(timeout: const Duration(seconds: 6));
      watch.stop();
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
      slow.release(_pos(1, 2, 5));
    });
  });

  group('rastreo en vivo y prefetch', () {
    test('fix del rastreo en vivo (≤ 2 min) se usa sin tocar el GPS', () async {
      var clock = DateTime(2026, 10, 20, 9);
      service = LocationService(now: () => clock);
      geo.streamPositions = [_pos(-16.7, -68.3, 9)];
      await service.stream().toList();
      geo.serviceEnabled = false; // ni siquiera se consulta el permiso
      clock = clock.add(const Duration(seconds: 90));
      final fix = await service.current();
      expect(fix?.lat, -16.7);
      expect(geo.currentCalls, 0);
    });

    test('prefetch calienta la posición para el próximo current', () async {
      geo.position = _pos(-16.8, -68.4, 6);
      service.prefetch();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(geo.currentCalls, 1);
      final fix = await service.current();
      expect(fix?.lat, -16.8);
      expect(geo.currentCalls, 1);
    });

    test('prefetch no prende el GPS si ya hay posición fresca', () async {
      geo.position = _pos(-16.8, -68.4, 6);
      service.prefetch();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      service.prefetch();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(geo.currentCalls, 1);
    });

    test('prefetch sin permiso no hace nada ni lanza', () async {
      geo.serviceEnabled = false;
      service.prefetch();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(geo.currentCalls, 0);
    });

    test('el permiso concedido se cachea: no se re-pregunta', () async {
      var clock = DateTime(2026, 10, 20, 9);
      service = LocationService(now: () => clock);
      final counting = _CountingGeolocator()..position = _pos(1, 2, 5);
      GeolocatorPlatform.instance = counting;
      expect((await service.current())?.lat, 1);
      final checks = counting.permissionChecks;
      expect(checks, greaterThan(0));

      // 10 min después la posición en memoria ya no sirve: nueva lectura,
      // pero sin volver a preguntar el permiso a la plataforma.
      clock = clock.add(const Duration(minutes: 10));
      counting.position = _pos(3, 4, 5);
      expect((await service.current())?.lat, 3);
      expect(counting.permissionChecks, checks);
      expect(counting.currentCalls, 2);
    });

    test('permiso denegado sí se re-chequea en cada llamada', () async {
      final counting = _CountingGeolocator()
        ..permission = LocationPermission.deniedForever;
      GeolocatorPlatform.instance = counting;
      expect(await service.current(), isNull);
      expect(await service.current(), isNull);
      expect(counting.permissionChecks, 2);
    });
  });
}

/// GPS que no responde hasta [release] (señal bajo techo).
class _SlowGeolocator extends _FakeGeolocator {
  final Completer<Position> _pending = Completer<Position>();

  void release(Position position) {
    if (!_pending.isCompleted) _pending.complete(position);
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    currentCalls++;
    return _pending.future;
  }
}

/// Cuenta las consultas de permiso a la plataforma.
class _CountingGeolocator extends _FakeGeolocator {
  int permissionChecks = 0;

  @override
  Future<LocationPermission> checkPermission() {
    permissionChecks++;
    return super.checkPermission();
  }
}

// Excepción simple que implementa Exception para ejercitar el `on Exception`
// de LocationService.current (geolocator lanza TimeoutException al vencer el
// timeLimit; aquí se usa un equivalente propio para no depender de dart:async).
class TimeoutException implements Exception {
  TimeoutException(this.message);
  final String message;
  @override
  String toString() => 'TimeoutException: $message';
}
