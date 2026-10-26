import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'location_gate_status.dart';
import 'location_required_view.dart';
import 'location_service.dart';

/// Resultado del permiso de ubicación "siempre" verificado en esta sesión:
/// `null` = todavía no se verificó, `true` = concedido, `false` = denegado.
///
/// NO es autoDispose a propósito: una vez concedido, las pantallas siguientes
/// del chofer no vuelven a preguntar a la plataforma ni muestran el spinner
/// (antes cada navegación sumaba 3 llamadas de plataforma y demoraba la ruta).
class BackgroundLocationPermissionNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  // ignore: use_setters_to_change_properties
  void set(bool granted) => state = granted;
}

/// Caché de sesión del permiso de ubicación "siempre" (ver
/// [BackgroundLocationPermissionNotifier]).
final backgroundLocationPermissionProvider =
    NotifierProvider<BackgroundLocationPermissionNotifier, bool?>(
      BackgroundLocationPermissionNotifier.new,
    );

/// Gate que exige el permiso de ubicación "Permitir siempre" (segundo plano)
/// antes de dejar operar el camión. El rastreo GPS es obligatorio: sin este
/// permiso no hay forma de saltear el flujo ni de trabajar sin ubicación.
///
/// Si en esta sesión el permiso ya se verificó concedido
/// ([backgroundLocationPermissionProvider]) muestra [child] al instante, sin
/// spinner. Si no, verifica (spinner); si falta, bloquea con una pantalla clara
/// que abre los ajustes del sistema ([ph.openAppSettings]) y re-verifica al
/// volver (AppLifecycle `resumed`) o con "Reintentar".
class LocationPermissionGate extends ConsumerStatefulWidget {
  const LocationPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LocationPermissionGate> createState() =>
      _LocationPermissionGateState();
}

class _LocationPermissionGateState extends ConsumerState<LocationPermissionGate>
    with WidgetsBindingObserver {
  LocationGateStatus _status = LocationGateStatus.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (ref.read(backgroundLocationPermissionProvider) == true) {
      _status = LocationGateStatus.granted;
    } else {
      _check();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de los ajustes del sistema, re-verificar el permiso sin que el
    // chofer tenga que tocar "Reintentar". Concedido no se re-chequea.
    if (state == AppLifecycleState.resumed &&
        _status == LocationGateStatus.denied) {
      _check();
    }
  }

  Future<void> _check() async {
    if (mounted && _status != LocationGateStatus.checking) {
      setState(() => _status = LocationGateStatus.checking);
    }
    final granted = await ref
        .read(locationServiceProvider)
        .ensureBackgroundPermission();
    if (!mounted) return;
    ref.read(backgroundLocationPermissionProvider.notifier).set(granted);
    setState(
      () => _status = granted
          ? LocationGateStatus.granted
          : LocationGateStatus.denied,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      LocationGateStatus.granted => widget.child,
      LocationGateStatus.checking => const Center(
        child: CircularProgressIndicator(),
      ),
      LocationGateStatus.denied => LocationRequiredView(
        onRetry: _check,
        onOpenSettings: () => ph.openAppSettings(),
      ),
    };
  }
}
