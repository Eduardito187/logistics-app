import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live_updates_promotion.dart';
import 'live_updates_support.dart';
import 'route_live_status.dart';

/// Puente con el canal nativo `bo.com.dismac/live_updates`:
/// - Android (`LiveUpdatesChannel.kt`): notificación de ruta en curso; en
///   Android 16 con `ProgressStyle` + chip en la barra de estado (promovida).
/// - iOS (`LiveUpdatesChannel.swift`): Live Activity (pantalla bloqueada +
///   Dynamic Island).
///
/// Nunca falla: sin canal (tests, escritorio → `MissingPluginException`) o
/// ante cualquier error del lado nativo, la llamada es un no-op silencioso. La
/// notificación en vivo es un extra; la ruta sigue igual sin ella.
class LiveUpdatesService {
  const LiveUpdatesService({MethodChannel channel = defaultChannel})
    : _channel = channel;

  static const MethodChannel defaultChannel = MethodChannel(
    'bo.com.dismac/live_updates',
  );

  final MethodChannel _channel;

  /// Qué soporta el teléfono (promoción en Android 16, Live Activities en iOS).
  Future<LiveUpdatesSupport> isSupported() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'isSupported',
      );
      return LiveUpdatesSupport.fromMap(map);
    } on Object {
      return LiveUpdatesSupport.none;
    }
  }

  /// Android 16: ¿se promueve la ruta en vivo (chip / isla)? y por qué no.
  /// Fuera de Android 16 (o sin canal) → [LiveUpdatesPromotionStatus.none].
  Future<LiveUpdatesPromotionStatus> promotionStatus() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'promotionStatus',
      );
      return LiveUpdatesPromotionStatus.fromMap(map);
    } on Object {
      return LiveUpdatesPromotionStatus.none;
    }
  }

  /// Abre los ajustes del sistema donde se activa "Live updates" para la app
  /// (o, si el teléfono no los tiene, los de notificaciones de la app).
  Future<bool> openPromotionSettings() =>
      _invoke('openPromotionSettings', null);

  /// Isla de DisTrack (Android): ¿existe en este teléfono y está concedido el
  /// permiso "Mostrar sobre otras apps"? Sin canal → `(false, false)`.
  Future<({bool supported, bool granted})> overlayStatus() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'overlayStatus',
      );
      return (
        supported: map?['supported'] == true,
        granted: map?['granted'] == true,
      );
    } on Object {
      return (supported: false, granted: false);
    }
  }

  /// Abre el ajuste del sistema "Mostrar sobre otras apps" de DisTrack.
  Future<bool> openOverlaySettings() => _invoke('openOverlaySettings', null);

  /// Muestra o actualiza la isla de DisTrack con la foto de la ruta (sin
  /// permiso, el nativo no hace nada y devuelve `false`).
  Future<bool> showOverlay(RouteLiveStatus status) =>
      _invoke('overlayShow', status.toMap());

  /// Quita la isla de DisTrack (libera la vista).
  Future<bool> hideOverlay() => _invoke('overlayHide', null);

  /// Pedir (o no) la promoción de Android 16 en la notificación de ruta. Se
  /// apaga cuando la isla elegida es la de DisTrack (no duplicar islas).
  Future<bool> setPromotionEnabled(bool enabled) =>
      _invoke('setPromotionEnabled', {'enabled': enabled});

  /// Muestra la ruta en vivo (si ya había una, el nativo la reemplaza).
  Future<bool> start(RouteLiveStatus status) =>
      _invoke('start', status.toMap());

  /// Actualiza la ruta en vivo ya mostrada.
  Future<bool> update(RouteLiveStatus status) =>
      _invoke('update', status.toMap());

  /// Quita la ruta en vivo. Con [last], iOS deja el estado final unos minutos
  /// en la pantalla bloqueada ("Ruta completada"); Android la quita al toque.
  Future<bool> end([RouteLiveStatus? last]) => _invoke('end', last?.toMap());

  Future<bool> _invoke(String method, Object? arguments) async {
    try {
      final ok = await _channel.invokeMethod<bool>(method, arguments);
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on Object {
      // Error del nativo (permiso de notificaciones negado, Live Activities
      // apagadas, etc.): no se interrumpe nada.
      return false;
    }
  }
}

/// Servicio de la ruta en vivo. Seam para tests: `overrideWithValue` con un
/// falso que registre las llamadas.
final liveUpdatesServiceProvider = Provider<LiveUpdatesService>(
  (ref) => const LiveUpdatesService(),
);

/// Estado de la promoción (fila "Ruta en la barra de estado" de Ajustes). Se
/// invalida al volver de los ajustes del sistema.
final liveUpdatesPromotionProvider =
    FutureProvider.autoDispose<LiveUpdatesPromotionStatus>(
      (ref) => ref.watch(liveUpdatesServiceProvider).promotionStatus(),
    );
