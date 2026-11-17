import 'package:geolocator/geolocator.dart';

/// Movimiento del camión según el GPS (ver `MotionDetector`).
enum TruckMotion { moving, stationary }

/// Perfil del rastreo del camión: cuánto GPS se pide y cada cuánto se encola y
/// se envía. Se elige con [TrackingProfile.resolve] según si el camión se mueve
/// y si el teléfono está ahorrando energía.
///
/// Por qué (batería): antes el GPS iba siempre en alta precisión cada 10 s y
/// cada posición era un POST inmediato, así que la radio celular no llegaba a
/// dormirse nunca (cada envío la deja ~10–15 s en alto consumo). Ahora:
/// - En marcha: GPS preciso cada 15 s, pero las posiciones se juntan y se
///   envían en ráfaga cada 60 s (la radio despierta 1 vez por minuto).
/// - Detenido (descargando, almuerzo, tráfico largo): precisión balanceada
///   (Wi-Fi/antenas, el chip GPS se apaga), lecturas cada 60 s y solo si se
///   movió 50 m; un latido cada 5 min mantiene al camión "vivo" en el mapa.
/// - Ahorro de energía / batería < 20 %: todo el doble de espaciado.
class TrackingProfile {
  const TrackingProfile._({
    required this.name,
    required this.accuracy,
    required this.androidDistanceFilterMeters,
    required this.iosDistanceFilterMeters,
    required this.interval,
    required this.minEnqueueInterval,
    required this.flushInterval,
    required this.heartbeatInterval,
  });

  /// En marcha, energía normal.
  ///
  /// Cadencia pedida por el dueño (nov 2026) para que el camión se vea FLUIDO en
  /// el mapa (antes saltaba: solo se movía cada 15 s): se CAPTURA/encola una
  /// posición cada **2 s** (si cambió de lugar) y se ENVÍA al backend en lote
  /// cada **10 s** (la radio despierta 1 vez cada 10 s, no por cada punto). El
  /// backend desglosa el lote punto por punto.
  static const TrackingProfile moving = TrackingProfile._(
    name: 'moving',
    accuracy: LocationAccuracy.high,
    // Android: sin filtro de distancia para recibir una lectura por intervalo
    // (2 s). El GPS está prendido igual; lo caro (la radio) se controla con el
    // envío por lotes cada 10 s.
    androidDistanceFilterMeters: 0,
    // iOS ignora el intervalo: un filtro chico para ~1 lectura cada pocos metros.
    iosDistanceFilterMeters: 8,
    interval: Duration(seconds: 2),
    minEnqueueInterval: Duration(seconds: 2),
    flushInterval: Duration(seconds: 10),
    heartbeatInterval: Duration(minutes: 5),
  );

  /// En marcha con ahorro de energía o batería baja: se espacia para cuidar la
  /// batería, pero sigue bastante más fluido que antes.
  static const TrackingProfile movingSaving = TrackingProfile._(
    name: 'movingSaving',
    accuracy: LocationAccuracy.high,
    androidDistanceFilterMeters: 0,
    iosDistanceFilterMeters: 16,
    // El doble de `moving` (ahorro de energía): 4 s captura, 20 s envío.
    interval: Duration(seconds: 4),
    minEnqueueInterval: Duration(seconds: 4),
    flushInterval: Duration(seconds: 20),
    heartbeatInterval: Duration(minutes: 10),
  );

  /// Detenido, energía normal: sin chip GPS (precisión balanceada).
  static const TrackingProfile stationary = TrackingProfile._(
    name: 'stationary',
    accuracy: LocationAccuracy.medium,
    androidDistanceFilterMeters: 50,
    iosDistanceFilterMeters: 50,
    interval: Duration(seconds: 60),
    minEnqueueInterval: Duration(seconds: 60),
    flushInterval: Duration(seconds: 120),
    heartbeatInterval: Duration(minutes: 5),
  );

  /// Detenido con ahorro de energía o batería baja.
  static const TrackingProfile stationarySaving = TrackingProfile._(
    name: 'stationarySaving',
    accuracy: LocationAccuracy.low,
    androidDistanceFilterMeters: 100,
    iosDistanceFilterMeters: 100,
    interval: Duration(seconds: 120),
    minEnqueueInterval: Duration(seconds: 120),
    flushInterval: Duration(seconds: 180),
    heartbeatInterval: Duration(minutes: 10),
  );

  /// Perfil para el [motion] actual y el estado de energía.
  static TrackingProfile resolve({
    required TruckMotion motion,
    required bool saveEnergy,
  }) => switch ((motion, saveEnergy)) {
    (TruckMotion.moving, false) => moving,
    (TruckMotion.moving, true) => movingSaving,
    (TruckMotion.stationary, false) => stationary,
    (TruckMotion.stationary, true) => stationarySaving,
  };

  /// Nombre corto (logs/tests).
  final String name;

  /// Precisión pedida al GPS. `high` prende el chip GPS; `medium`/`low` usan
  /// Wi-Fi y antenas (mucho menos consumo).
  final LocationAccuracy accuracy;

  /// Filtro de distancia (m) en Android.
  final int androidDistanceFilterMeters;

  /// Filtro de distancia (m) en iOS.
  final int iosDistanceFilterMeters;

  /// Intervalo mínimo entre lecturas (Android; iOS lo ignora).
  final Duration interval;

  /// Separación mínima entre posiciones encoladas.
  final Duration minEnqueueInterval;

  /// Cada cuánto se envía el lote de posiciones juntadas.
  final Duration flushInterval;

  /// Con el camión quieto, cada cuánto se reenvía su posición (latido) para
  /// que el supervisor lo siga viendo activo.
  final Duration heartbeatInterval;

  @override
  String toString() => 'TrackingProfile($name)';
}
