import 'package:flutter/foundation.dart';

/// Qué puede mostrar el teléfono de la ruta en vivo (respuesta de
/// `isSupported` del canal nativo).
@immutable
class LiveUpdatesSupport {
  const LiveUpdatesSupport({
    this.androidPromoted = false,
    this.androidSdk = 0,
    this.iosLiveActivities = false,
  });

  /// Sin canal nativo (tests, escritorio) o error: nada especial disponible.
  static const LiveUpdatesSupport none = LiveUpdatesSupport();

  /// Android 16+: el sistema deja PROMOVER la notificación (chip en la barra
  /// de estado / Now Bar). `NotificationManager.canPostPromotedNotifications`.
  final bool androidPromoted;

  /// `Build.VERSION.SDK_INT` del teléfono (0 si no es Android).
  final int androidSdk;

  /// iOS 16.1+ con las Live Activities habilitadas por el usuario
  /// (`ActivityAuthorizationInfo().areActivitiesEnabled`).
  final bool iosLiveActivities;

  /// Lee el mapa `{android:{promoted, sdk}, ios:{liveActivities}}`; tolera
  /// claves faltantes o de otro tipo.
  factory LiveUpdatesSupport.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return none;
    final android = map['android'];
    final ios = map['ios'];
    return LiveUpdatesSupport(
      androidPromoted: android is Map && android['promoted'] == true,
      androidSdk: android is Map && android['sdk'] is int
          ? android['sdk'] as int
          : 0,
      iosLiveActivities: ios is Map && ios['liveActivities'] == true,
    );
  }
}
