import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'gps_fix.dart';

// Se reexporta [GpsFix] (movido a su propio archivo por SRP) para no romper a
// quienes importan `location/location_service.dart`.
export 'gps_fix.dart';

/// Acceso al GPS del dispositivo. Pide permiso una vez y entrega la posición.
/// En terreno un escaneo no debe trabarse si el GPS tarda: devuelve `null` si
/// no hay fix a tiempo, y el escaneo sigue igual (offline-first).
class LocationService {
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Permiso de ubicación "siempre" (segundo plano), necesario para que el
  /// rastreo del camión siga enviando con la app minimizada.
  ///
  /// En Android 10+ primero hay que tener el permiso en primer plano
  /// ([ensurePermission]) y recién después se puede pedir el de segundo plano.
  /// Devuelve `false` si el servicio de ubicación está apagado o si el usuario
  /// no concede el permiso "siempre".
  Future<bool> ensureBackgroundPermission() async {
    if (!await ensurePermission()) return false;
    var status = await ph.Permission.locationAlways.status;
    if (!status.isGranted) {
      status = await ph.Permission.locationAlways.request();
    }
    return status.isGranted;
  }

  /// Posición actual, o `null` si no hay permiso o se agota el tiempo.
  Future<GpsFix?> current({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (!await ensurePermission()) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return GpsFix(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
      );
    } on Exception {
      return null;
    }
  }

  /// Flujo de posiciones para la telemetría en vivo del camión (chofer en ruta).
  Stream<GpsFix> stream({int distanceFilterMeters = 20}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).map(
      (p) => GpsFix(lat: p.latitude, lng: p.longitude, accuracy: p.accuracy),
    );
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
