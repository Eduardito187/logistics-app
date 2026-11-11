import 'package:flutter/foundation.dart';

/// Qué ve el chofer en Ajustes sobre la ruta en la barra de estado.
enum LiveUpdatesPromotionState {
  /// No aplica: iOS, Android < 16 o sin canal nativo. La fila no se muestra.
  unsupported,

  /// Android 16 deja promover la notificación: chip en la barra de estado /
  /// isla del fabricante.
  active,

  /// El usuario (o el sistema) apagó las notificaciones, el canal de la ruta o
  /// "Live updates" para la app: se puede volver a activar en los ajustes.
  disabledBySystem,

  /// Android 16 pero el teléfono no promueve esta notificación (ROM del
  /// fabricante sin soporte): no hay nada que activar.
  unavailable,
}

/// Diagnóstico de la promoción de la ruta en vivo (Live Updates de Android
/// 16): respuesta de `promotionStatus` del canal `bo.com.dismac/live_updates`.
@immutable
class LiveUpdatesPromotionStatus {
  const LiveUpdatesPromotionStatus({
    this.sdk = 0,
    this.canPostPromoted = false,
    this.promotable = false,
    this.reasons = const [],
  });

  /// Sin canal (tests, iOS, escritorio) o error.
  static const LiveUpdatesPromotionStatus none = LiveUpdatesPromotionStatus();

  /// Android de la primera versión con Live Updates (16).
  static const int minSdk = 36;

  /// Razones que el usuario puede corregir desde los ajustes del sistema.
  static const Set<String> userFixableReasons = {
    'notificationsDisabled',
    'channelBlocked',
    'channelImportanceMin',
    'promotionDenied',
  };

  /// `Build.VERSION.SDK_INT` (0 si no es Android).
  final int sdk;

  /// `NotificationManager.canPostPromotedNotifications()`: el usuario no
  /// apagó "Live updates" para la app.
  final bool canPostPromoted;

  /// `Notification.hasPromotableCharacteristics()` sobre la notificación de
  /// ruta tal como se arma (ongoing, con título, sin colorizar, estilo
  /// permitido…).
  final bool promotable;

  /// Por qué NO se promueve (vacío si todo está bien). Claves del nativo:
  /// `sdk`, `notificationsDisabled`, `channelBlocked`,
  /// `channelImportanceMin`, `promotionDenied`, `colorized`, `notOngoing`,
  /// `noTitle`, `notPromotable`.
  final List<String> reasons;

  /// Estado para la UI.
  LiveUpdatesPromotionState get state {
    if (sdk < minSdk) return LiveUpdatesPromotionState.unsupported;
    if (reasons.any(userFixableReasons.contains)) {
      return LiveUpdatesPromotionState.disabledBySystem;
    }
    if (canPostPromoted && promotable) return LiveUpdatesPromotionState.active;
    return LiveUpdatesPromotionState.unavailable;
  }

  /// Lee `{sdk, canPostPromoted, promotable, reasons:[…]}`; tolera claves
  /// faltantes o de otro tipo.
  factory LiveUpdatesPromotionStatus.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return none;
    final sdk = map['sdk'];
    final reasons = map['reasons'];
    return LiveUpdatesPromotionStatus(
      sdk: sdk is int ? sdk : 0,
      canPostPromoted: map['canPostPromoted'] == true,
      promotable: map['promotable'] == true,
      reasons: reasons is List
          ? List.unmodifiable(reasons.whereType<String>())
          : const [],
    );
  }
}
