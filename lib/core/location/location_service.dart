import 'dart:async';

import 'package:flutter/foundation.dart';
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
  LocationService({DateTime Function()? now}) : _now = now ?? DateTime.now;

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

  /// Reloj inyectable (tests).
  final DateTime Function() _now;

  /// Antigüedad máxima del último fix del rastreo en vivo ([stream]) para
  /// usarlo directo en [current].
  static const Duration liveFixMaxAge = Duration(minutes: 2);

  /// Antigüedad máxima de la última posición conocida para reutilizarla en vez
  /// de prender el GPS (ver [current]). En andén/tienda el lugar no cambia.
  static const Duration lastKnownMaxAge = Duration(minutes: 5);

  /// Precisión mínima (m) de la última posición conocida para reutilizarla.
  static const double lastKnownMaxAccuracyMeters = 200;

  /// Espera máxima TOTAL de [current] por una lectura nueva: un escaneo nunca
  /// se traba esperando al GPS (regla 4).
  static const Duration currentMaxWait = Duration(milliseconds: 1500);

  /// Tope de la lectura nueva que corre en segundo plano ([prefetch] o la que
  /// dejó [current] al vencer su espera): al terminar calienta la caché.
  static const Duration backgroundFixTimeLimit = Duration(seconds: 15);

  /// `true` si [pos] es lo bastante reciente y precisa como para no pedir
  /// otra lectura al GPS.
  @visibleForTesting
  static bool isFreshEnough(Position pos, {DateTime? now}) => _isFresh(
    pos.timestamp,
    pos.accuracy,
    now ?? DateTime.now(),
    lastKnownMaxAge,
  );

  static bool _isFresh(
    DateTime at,
    double? accuracy,
    DateTime now,
    Duration maxAge,
  ) {
    final age = now.difference(at);
    return !age.isNegative &&
        age <= maxAge &&
        accuracy != null &&
        accuracy > 0 &&
        accuracy <= lastKnownMaxAccuracyMeters;
  }

  /// Último fix del rastreo en vivo ([stream]) y cuándo llegó.
  GpsFix? _liveFix;
  DateTime? _liveFixAt;

  /// Última posición conocida en memoria (de [current], [prefetch] o del
  /// sistema) con su hora de lectura.
  GpsFix? _lastFix;
  DateTime? _lastFixAt;

  /// Lectura nueva en curso: [current] y [prefetch] la comparten (nunca se
  /// prenden dos lecturas a la vez).
  Future<GpsFix?>? _pendingFix;

  /// Permiso concedido ya verificado en esta sesión: no se vuelve a preguntar
  /// a la plataforma en cada escaneo. Si estaba denegado se re-chequea.
  bool _permissionGranted = false;

  Future<bool> _hasPermission() async {
    if (_permissionGranted) return true;
    final granted = await ensurePermission();
    _permissionGranted = granted;
    return granted;
  }

  void _remember(GpsFix fix, DateTime at) {
    final previous = _lastFixAt;
    if (previous != null && previous.isAfter(at)) return;
    _lastFix = fix;
    _lastFixAt = at;
  }

  static GpsFix _toFix(Position p) =>
      GpsFix(lat: p.latitude, lng: p.longitude, accuracy: p.accuracy);

  /// Posición actual, o `null` si no hay permiso ni ninguna posición conocida.
  ///
  /// Nunca bloquea más de [currentMaxWait] (aunque [timeout] pida más). Orden:
  /// 1. Último fix del rastreo en vivo si tiene ≤ [liveFixMaxAge].
  /// 2. Última posición conocida (memoria o `getLastKnownPosition`) si tiene
  ///    ≤ [lastKnownMaxAge] y precisión ≤ [lastKnownMaxAccuracyMeters].
  /// 3. Lectura nueva, esperando a lo sumo [currentMaxWait] (o [timeout] si es
  ///    menor); si no llega, sigue en segundo plano y calienta la caché.
  /// 4. La última conocida aunque sea vieja, o `null`.
  Future<GpsFix?> current({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final now = _now();
    final live = _liveFix;
    final liveAt = _liveFixAt;
    if (live != null &&
        liveAt != null &&
        !now.difference(liveAt).isNegative &&
        now.difference(liveAt) <= liveFixMaxAge) {
      return live;
    }
    if (_freshInMemory(now)) return _lastFix;

    if (!await _hasPermission()) return null;
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _remember(_toFix(last), last.timestamp);
        if (_freshInMemory(_now())) return _lastFix;
      }
    } on Object {
      // Sin última posición (web, plugin viejo): se pide una lectura nueva.
    }

    final wait = timeout < currentMaxWait ? timeout : currentMaxWait;
    try {
      final fix = await _requestFix().timeout(wait);
      if (fix != null) return fix;
    } on TimeoutException {
      // La lectura sigue en segundo plano y deja la posición para el próximo.
    }
    return _lastFix;
  }

  bool _freshInMemory(DateTime now) {
    final at = _lastFixAt;
    final fix = _lastFix;
    return fix != null &&
        at != null &&
        _isFresh(at, fix.accuracy, now, lastKnownMaxAge);
  }

  /// Lectura nueva compartida; nunca lanza (devuelve `null` si falla).
  Future<GpsFix?> _requestFix() {
    final pending = _pendingFix;
    if (pending != null) return pending;
    final request = () async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: backgroundFixTimeLimit,
          ),
        );
        final fix = _toFix(pos);
        _remember(fix, _now());
        return fix;
      } on Object {
        return null;
      } finally {
        _pendingFix = null;
      }
    }();
    _pendingFix = request;
    return request;
  }

  /// Calienta la posición en segundo plano (sin esperar): las pantallas de
  /// escaneo lo llaman al abrir la cámara para que, al registrar el bulto,
  /// [current] ya tenga una posición fresca y no espere al GPS. No hace nada si
  /// ya hay una posición reciente o una lectura en curso. Nunca lanza.
  void prefetch() {
    unawaited(_prefetch());
  }

  Future<void> _prefetch() async {
    try {
      final now = _now();
      final liveAt = _liveFixAt;
      if (liveAt != null && now.difference(liveAt) <= liveFixMaxAge) return;
      if (_freshInMemory(now) || _pendingFix != null) return;
      if (!await _hasPermission()) return;
      await _requestFix();
    } on Object {
      // Best-effort: sin permiso/plugin no se calienta nada.
    }
  }

  /// Intervalo mínimo que se le pide al GPS de Android entre lecturas.
  ///
  /// Sin esto el FusedLocationProvider entrega ~1 lectura/seg con el camión en
  /// movimiento: batería, CPU y una fila en la cola por segundo. Junto con el
  /// filtro de distancia, alcanza para seguir un camión en ciudad.
  static const Duration streamInterval = Duration(seconds: 10);

  /// Ajustes del flujo de posiciones (expuestos para test).
  ///
  /// [highAccuracy] `true` (GPS) solo con ruta activa; en `false` se pide
  /// precisión balanceada (red/Wi-Fi, ~100 m), que gasta mucha menos batería.
  ///
  /// - Android: intervalo mínimo [streamInterval] (FusedLocationProvider).
  /// - iOS: `automotiveNavigation` (iOS ajusta el GPS a un vehículo en ruta) y
  ///   SIN pausa automática: con la pausa, iOS corta las posiciones en una
  ///   parada larga y en segundo plano no las retoma solo, y el camión
  ///   "desaparece" del seguimiento. La batería la cuida el filtro de distancia.
  @visibleForTesting
  static LocationSettings streamSettings({
    required int distanceFilterMeters,
    TargetPlatform? platform,
    bool highAccuracy = true,
  }) {
    final accuracy = highAccuracy
        ? LocationAccuracy.high
        : LocationAccuracy.medium;
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilterMeters,
          intervalDuration: streamInterval,
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilterMeters,
          activityType: ActivityType.automotiveNavigation,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilterMeters,
        );
    }
  }

  /// Flujo de posiciones para la telemetría en vivo del camión (chofer en ruta,
  /// por eso precisión alta). Filtra por distancia ([distanceFilterMeters]) y,
  /// en Android, por intervalo ([streamInterval]).
  Stream<GpsFix> stream({int distanceFilterMeters = 20}) {
    return Geolocator.getPositionStream(
      locationSettings: streamSettings(
        distanceFilterMeters: distanceFilterMeters,
      ),
    ).map((p) {
      final fix = _toFix(p);
      // El rastreo en vivo deja su último fix para [current]: el escaneo del
      // chofer con ruta activa no prende otra lectura.
      final at = _now();
      _liveFix = fix;
      _liveFixAt = at;
      _remember(fix, at);
      return fix;
    });
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
