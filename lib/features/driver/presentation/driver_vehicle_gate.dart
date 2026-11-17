import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
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
    // la ruta y el mapa siguen; el tiempo real / reintento lo corrige.
    final myCrew = crew.value;

    // RED DE SEGURIDAD (nunca perder la ruta en curso): la ruta se observa
    // SIEMPRE. Si `my-crew` no devuelve asignación —una entrega que cruzó la
    // medianoche, que lleva días abierta por un envío largo, un bloqueo o un
    // problema de ruta—, `assignedVehicleId` cae al último camión conocido y
    // acá se recupera su RUTA ABIERTA. El camión con el que se opera sale de la
    // cuadrilla o, si no hay, de esa ruta recuperada. Solo se bloquea cuando no
    // hay NI cuadrilla NI ruta abierta (sin asignación real / sin red al abrir).
    final route = ref.watch(driverRouteProvider);
    // Solo se recupera una ruta EN CURSO: cubre en progreso, planificada y
    // SUSPENDIDA (bloqueo o incidente de ruta), que siguen siendo la entrega
    // del chofer. Una ruta ya CERRADA/COMPLETADA no revive el gate.
    final candidate = route.value;
    final openRoute =
        (candidate != null &&
            candidate.closedAt == null &&
            candidate.status != DriverRouteStatus.completed)
        ? candidate
        : null;
    final vehicleId = myCrew?.vehicle.id ?? openRoute?.vehicleId;

    final Widget body;
    if (vehicleId != null) {
      // Sin cuadrilla (ruta recuperada por respaldo) no hay cabecera de
      // asignación que mostrar: se opera directo sobre la ruta.
      final headerless = immersive || myCrew == null;
      body = LocationPermissionGate(
        child: DriverTrackingAutostart(
          child: headerless
              ? builder(context, vehicleId)
              : Column(
                  children: [
                    AssignmentHeader(crew: myCrew),
                    const Divider(height: 1),
                    Expanded(child: builder(context, vehicleId)),
                  ],
                ),
        ),
      );
    } else if (crew.isLoading || route.isLoading) {
      body = const Center(
        child: Padding(padding: EdgeInsets.all(48), child: BrandLoader()),
      );
    } else {
      // Sin camión conocido NI ruta abierta Y con error: ahí sí es sin
      // asignación / sin red.
      final error = crew.error;
      body = NoAssignment(
        message: error is ApiException && error.isConnectionError
            ? error.message
            : null,
        onRetry: () {
          ref.invalidate(myCrewProvider);
          ref.invalidate(driverRouteProvider);
        },
      );
    }
    final bareScaffold = immersive && vehicleId != null;
    return Scaffold(
      appBar: bareScaffold
          ? null
          : AppBar(title: Text(title), actions: actions),
      body: body,
    );
  }
}
