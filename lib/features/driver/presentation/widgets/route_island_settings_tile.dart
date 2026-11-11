import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/live_updates/live_updates_promotion.dart';
import '../../../../core/live_updates/live_updates_service.dart';
import '../../../../core/live_updates/route_island.dart';

/// Fila "Isla de ruta" de Ajustes (solo rol chofer).
///
/// - Android 7+: estado de la isla y lo que se puede hacer:
///   [Activar en el sistema] (Live Updates de Android 16 apagado),
///   [Permitir isla de DisTrack] (permiso "Mostrar sobre otras apps") y, si
///   las dos están disponibles, el selector Sistema / DisTrack.
/// - iOS: texto informativo (Dynamic Island / pantalla de bloqueo), sin
///   controles.
/// - Otros roles u otras plataformas: no se muestra.
///
/// Al volver de los ajustes del sistema se vuelve a consultar el estado.
class RouteIslandSettingsTile extends ConsumerStatefulWidget {
  const RouteIslandSettingsTile({super.key});

  @override
  ConsumerState<RouteIslandSettingsTile> createState() =>
      _RouteIslandSettingsTileState();
}

class _RouteIslandSettingsTileState
    extends ConsumerState<RouteIslandSettingsTile> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(routeIslandAvailabilityProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = ref.watch(
      sessionProvider.select((s) => s?.role == UserRole.driver),
    );
    if (!isDriver) return const SizedBox.shrink();

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const ListTile(
          key: Key('routeIslandTile'),
          contentPadding: EdgeInsets.zero,
          leading: AnimatedAppIcon(AppIcon.deliver, excludeFromSemantics: true),
          title: Text('Isla de ruta'),
          subtitle: Text(
            'En iPhone 14 Pro o posterior la ruta aparece en la Dynamic '
            'Island; en otros iPhone (iOS 16.1+) en la pantalla de bloqueo.',
          ),
        );
      case TargetPlatform.android:
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return const SizedBox.shrink();
    }

    final availability = ref.watch(routeIslandAvailabilityProvider).value;
    if (availability == null || !availability.overlaySupported) {
      return const SizedBox.shrink();
    }
    final preference = ref.watch(routeIslandPreferenceProvider);
    final mode = resolveRouteIslandMode(availability, preference);
    final service = ref.read(liveUpdatesServiceProvider);
    final systemFixable =
        availability.promotion.state ==
        LiveUpdatesPromotionState.disabledBySystem;
    final bothAvailable =
        availability.systemAvailable && availability.overlayAvailable;

    return Column(
      key: const Key('routeIslandTile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: AnimatedAppIcon(
            AppIcon.deliver,
            state: mode == RouteIslandMode.none
                ? AppIconState.idle
                : AppIconState.active,
            excludeFromSemantics: true,
          ),
          title: const Text('Isla de ruta'),
          subtitle: Text(_statusText(mode)),
        ),
        if (bothAvailable)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<RouteIslandMode>(
              key: const Key('routeIslandSelector'),
              segments: const [
                ButtonSegment(
                  value: RouteIslandMode.system,
                  label: Text('Isla del sistema'),
                ),
                ButtonSegment(
                  value: RouteIslandMode.overlay,
                  label: Text('Isla de DisTrack'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                final picked = selection.first == RouteIslandMode.overlay
                    ? RouteIslandPreference.overlay
                    : RouteIslandPreference.system;
                unawaited(
                  ref.read(routeIslandPreferenceProvider.notifier).set(picked),
                );
              },
            ),
          ),
        if (systemFixable)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: const Key('routeIslandEnableSystem'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => unawaited(service.openPromotionSettings()),
              child: const Text('Activar en el sistema'),
            ),
          ),
        if (!availability.overlayGranted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: const Key('routeIslandAllowOverlay'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => unawaited(service.openOverlaySettings()),
              child: const Text('Permitir isla de DisTrack'),
            ),
          ),
      ],
    );
  }

  static String _statusText(RouteIslandMode mode) {
    switch (mode) {
      case RouteIslandMode.system:
        return 'Activa: la ruta se ve en la barra de estado del teléfono.';
      case RouteIslandMode.overlay:
        return 'Activa: la isla de DisTrack se ve arriba de la pantalla.';
      case RouteIslandMode.none:
        return 'Desactivada: la ruta solo se ve en las notificaciones.';
    }
  }
}
