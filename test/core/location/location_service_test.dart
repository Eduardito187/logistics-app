// Se importan las PlatformInterface (transitivas) para sustituir los plugins en
// test; es la forma soportada de mockearlos sin plataforma real.
// ignore_for_file: depend_on_referenced_packages
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

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
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
