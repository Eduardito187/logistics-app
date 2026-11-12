import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import 'live_updates_promotion.dart';
import 'live_updates_service.dart';

/// Dónde se ve la "isla" de la ruta del chofer en Android con la app en
/// segundo plano. La notificación de ruta se publica SIEMPRE (la exige el
/// foreground service); esto decide el extra que va arriba de la pantalla.
enum RouteIslandMode {
  /// Ninguna isla: solo la notificación (sin permisos ni Android 16).
  none,

  /// Isla del sistema: Live Update promovido de Android 16 (chip en la barra
  /// de estado / Now Bar / Live Alerts / cápsula según el fabricante).
  system,

  /// Isla de DisTrack: pastilla flotante propia (permiso "Mostrar sobre otras
  /// apps"), en cualquier Android 7+. La notificación va SIN pedido de
  /// promoción para no duplicar con el chip del sistema.
  overlay,
}

/// Preferencia del chofer cuando las dos islas están disponibles.
enum RouteIslandPreference {
  system('system'),
  overlay('overlay');

  const RouteIslandPreference(this.storageValue);

  final String storageValue;

  static RouteIslandPreference? parse(String? raw) {
    for (final value in values) {
      if (value.storageValue == raw) return value;
    }
    return null;
  }
}

/// Qué islas puede mostrar este teléfono ahora.
@immutable
class RouteIslandAvailability {
  const RouteIslandAvailability({
    this.promotion = LiveUpdatesPromotionStatus.none,
    this.overlaySupported = false,
    this.overlayGranted = false,
  });

  static const RouteIslandAvailability none = RouteIslandAvailability();

  /// Live Updates de Android 16 (isla del sistema).
  final LiveUpdatesPromotionStatus promotion;

  /// Android (7+): la isla propia existe en este teléfono.
  final bool overlaySupported;

  /// Permiso "Mostrar sobre otras apps" concedido.
  final bool overlayGranted;

  /// ¿El teléfono puede mostrar la isla del SISTEMA?
  ///
  /// Ojo: con la isla de DisTrack elegida, la notificación de ruta se arma SIN
  /// el pedido de promoción (una sola isla), así que el nativo reporta
  /// `promotable: false` y el estado cae en `unavailable` aunque el teléfono sí
  /// sepa promoverla. `canPostPromoted` NO depende de cómo armamos la
  /// notificación (es el permiso "Live updates" de la app), así que se usa para
  /// no perder la isla del sistema —ni el selector de Ajustes— al pasarse a la
  /// de DisTrack.
  bool get systemAvailable {
    final state = promotion.state;
    if (state == LiveUpdatesPromotionState.active) return true;
    return state == LiveUpdatesPromotionState.unavailable &&
        promotion.canPostPromoted;
  }

  bool get overlayAvailable => overlaySupported && overlayGranted;
}

/// Elige UNA isla (nunca las dos a la vez). La isla del SISTEMA (chip en la
/// barra de estado) es la preferida; la pastilla flotante (overlay) es
/// INTRUSIVA —dibuja sobre otras apps— así que SOLO se usa si el chofer la
/// eligió explícitamente, nunca por defecto:
/// - Isla del sistema disponible → esa (salvo que el chofer prefiera el overlay).
/// - Sin isla del sistema → overlay SOLO si el chofer lo eligió; si no,
///   [RouteIslandMode.none] (queda la notificación / chip, nunca el overlay).
RouteIslandMode resolveRouteIslandMode(
  RouteIslandAvailability availability,
  RouteIslandPreference? preference,
) {
  final system = availability.systemAvailable;
  final overlay = availability.overlayAvailable;
  final wantsOverlay = preference == RouteIslandPreference.overlay;
  if (system) {
    return overlay && wantsOverlay
        ? RouteIslandMode.overlay
        : RouteIslandMode.system;
  }
  // Sin isla del sistema: el overlay flotante NO es el default (es intrusivo).
  // Solo si el chofer lo eligió explícitamente; si no, queda la notificación.
  if (overlay && wantsOverlay) return RouteIslandMode.overlay;
  return RouteIslandMode.none;
}

/// Preferencia "Isla del sistema" / "Isla de DisTrack" del teléfono,
/// persistida en el almacén seguro (`null` = automática: la del sistema).
class RouteIslandPreferenceNotifier extends Notifier<RouteIslandPreference?> {
  /// Clave en el almacén seguro.
  static const storageKey = 'pref_route_island';

  bool _changedByUser = false;

  @override
  RouteIslandPreference? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(tokenStoreProvider).readPref(storageKey);
      // Si el chofer ya eligió (la lectura del almacén tarda), manda su
      // elección: la precarga del almacén no ve las escrituras directas.
      if (!ref.mounted || _changedByUser || state != null) return;
      state = RouteIslandPreference.parse(raw);
    } on Object {
      // Almacén no disponible: queda la automática.
    }
  }

  /// Elige la isla y la guarda.
  Future<void> set(RouteIslandPreference value) async {
    _changedByUser = true;
    state = value;
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: storageKey, value: value.storageValue);
    } on Object {
      // Si no se pudo guardar, igual rige mientras la app siga abierta.
    }
  }
}

final routeIslandPreferenceProvider =
    NotifierProvider<RouteIslandPreferenceNotifier, RouteIslandPreference?>(
      RouteIslandPreferenceNotifier.new,
    );

/// Disponibilidad de las islas (Android). Se invalida al volver a la app
/// (el chofer pudo dar el permiso o activar "Live updates" en los ajustes).
final routeIslandAvailabilityProvider =
    FutureProvider.autoDispose<RouteIslandAvailability>((ref) async {
      if (defaultTargetPlatform != TargetPlatform.android) {
        return RouteIslandAvailability.none;
      }
      final service = ref.watch(liveUpdatesServiceProvider);
      final promotion = await service.promotionStatus();
      final overlay = await service.overlayStatus();
      return RouteIslandAvailability(
        promotion: promotion,
        overlaySupported: overlay.supported,
        overlayGranted: overlay.granted,
      );
    });

/// Isla efectiva (lo que usa la ruta en vivo). Mientras se consulta la
/// disponibilidad: [RouteIslandMode.none].
final routeIslandModeProvider = Provider.autoDispose<RouteIslandMode>((ref) {
  final availability = ref.watch(routeIslandAvailabilityProvider).value;
  if (availability == null) return RouteIslandMode.none;
  return resolveRouteIslandMode(
    availability,
    ref.watch(routeIslandPreferenceProvider),
  );
});
