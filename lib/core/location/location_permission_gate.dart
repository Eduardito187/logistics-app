import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'location_gate_status.dart';
import 'location_required_view.dart';
import 'location_service.dart';

/// Gate que exige el permiso de ubicación "Permitir siempre" (segundo plano)
/// antes de dejar operar el camión. El rastreo GPS es obligatorio: sin este
/// permiso no hay forma de saltear el flujo ni de trabajar sin ubicación.
///
/// Mientras verifica muestra un spinner; si el permiso está concedido muestra
/// [child]; si falta, bloquea con una pantalla clara que abre los ajustes del
/// sistema ([ph.openAppSettings]) y permite reintentar al volver.
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
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de los ajustes del sistema, re-verificar el permiso sin que el
    // chofer tenga que tocar "Reintentar".
    if (state == AppLifecycleState.resumed &&
        _status == LocationGateStatus.denied) {
      _check();
    }
  }

  Future<void> _check() async {
    setState(() => _status = LocationGateStatus.checking);
    final granted = await ref
        .read(locationServiceProvider)
        .ensureBackgroundPermission();
    if (!mounted) return;
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
