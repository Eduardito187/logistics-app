import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_permission_gate.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_loader.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/driver_tracking_autostart.dart';
import 'widgets/assignment_header.dart';
import 'widgets/no_assignment.dart';

/// Envuelve una pantalla de operación del chofer. El chofer NO elige vehículo ni
/// tripulación: se le ASIGNAN. El gate lee la asignación del día
/// ([myCrewProvider]) y:
///
/// - cargando → spinner;
/// - con datos → exige el permiso de ubicación "siempre" (el rastreo del camión
///   es obligatorio), muestra una cabecera con la asignación (placa, chofer,
///   ayudantes, turno) y el contenido construido con el `vehicleId` asignado;
/// - 404/sin asignación → pantalla de bloqueo para contactar al supervisor.
///
/// Con datos y permiso concedidos monta [DriverTrackingAutostart], que inicia el
/// rastreo GPS automáticamente cuando hay una parada activa.
class DriverVehicleGate extends ConsumerWidget {
  const DriverVehicleGate({
    super.key,
    required this.title,
    required this.builder,
    this.actions,
    this.immersive = false,
  });

  final String title;
  final Widget Function(BuildContext context, String vehicleId) builder;
  final List<Widget>? actions;

  /// Pantalla a pantalla completa (p. ej. entrega en curso sobre el mapa): sin
  /// AppBar ni cabecera de asignación cuando hay datos. Los estados de carga,
  /// error y permiso siguen mostrando la AppBar para poder volver.
  final bool immersive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crew = ref.watch(myCrewProvider);
    // ÚLTIMO camión conocido: se conserva aunque la recarga falle (red caída,
    // 5xx transitorio). Antes, un error transitorio de `my-crew` tiraba el gate
    // a "camión no asignado" y el mapa dejaba de cargar, aunque el camión ya se
    // conocía. Con esto, una vez cargado, un blip de red NO desasigna el camión:
    // la ruta y el mapa siguen; el tiempo real / reintento lo corrige. Solo se
    // bloquea cuando NUNCA hubo camión (sin asignación real / sin red al abrir).
    final myCrew = crew.value;
    if (myCrew != null) {
      // La ruta se pide en cuanto hay vehículo, EN PARALELO al chequeo del
      // permiso de ubicación (que solo condiciona el GPS/mapa, no los datos):
      // cuando el permiso responde, la ruta ya está llegando o en caché.
      ref.listen(driverRouteProvider, (_, _) {});
    }
    final bare = immersive && myCrew != null;
    final Widget body;
    if (myCrew != null) {
      body = LocationPermissionGate(
        child: DriverTrackingAutostart(
          child: immersive
              ? builder(context, myCrew.vehicle.id)
              : Column(
                  children: [
                    AssignmentHeader(crew: myCrew),
                    const Divider(height: 1),
                    Expanded(child: builder(context, myCrew.vehicle.id)),
                  ],
                ),
        ),
      );
    } else if (crew.isLoading) {
      body = const Center(
        child: Padding(padding: EdgeInsets.all(48), child: BrandLoader()),
      );
    } else {
      // Sin camión conocido Y con error: ahí sí es sin asignación / sin red.
      final error = crew.error;
      body = NoAssignment(
        message: error is ApiException && error.isConnectionError
            ? error.message
            : null,
        onRetry: () => ref.invalidate(myCrewProvider),
      );
    }
    return Scaffold(
      appBar: bare ? null : AppBar(title: Text(title), actions: actions),
      body: body,
    );
  }
}
