import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_permission_gate.dart';
import '../../../core/network/api_exception.dart';
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
  });

  final String title;
  final Widget Function(BuildContext context, String vehicleId) builder;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crew = ref.watch(myCrewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: crew.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => NoAssignment(
          message: error is ApiException && error.isConnectionError
              ? error.message
              : null,
          onRetry: () => ref.invalidate(myCrewProvider),
        ),
        data: (myCrew) => LocationPermissionGate(
          child: DriverTrackingAutostart(
            child: Column(
              children: [
                AssignmentHeader(crew: myCrew),
                const Divider(height: 1),
                Expanded(child: builder(context, myCrew.vehicle.id)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
