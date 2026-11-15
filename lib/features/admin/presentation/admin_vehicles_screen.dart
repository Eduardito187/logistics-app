import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/admin_remote_data_source.dart';
import '../domain/entities/admin_vehicle.dart';
import '../domain/entities/maintenance_result.dart';
import '../../../core/widgets/paged_search_list.dart';
import 'widgets/send_to_maintenance_sheet.dart';

/// Camiones de la flota para el administrador: buscar por placa, filtrar por
/// estado y mandar un camión a mantenimiento.
class AdminVehiclesScreen extends ConsumerStatefulWidget {
  const AdminVehiclesScreen({super.key});

  @override
  ConsumerState<AdminVehiclesScreen> createState() =>
      _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends ConsumerState<AdminVehiclesScreen> {
  final GlobalKey<PagedSearchListState<AdminVehicle>> _list = GlobalKey();

  /// `null` = todos los estados.
  AdminVehicleStatus? _status;

  static const List<AdminVehicleStatus> _filters = [
    AdminVehicleStatus.available,
    AdminVehicleStatus.inService,
    AdminVehicleStatus.maintenance,
    AdminVehicleStatus.inactive,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camiones')),
      body: PagedSearchList<AdminVehicle>(
        key: _list,
        searchLabel: 'Buscar por placa',
        emptyTitle: 'Sin camiones',
        emptyIcon: AppIcon.deliver,
        filterKey: _status,
        filters: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('Todos', null),
              for (final status in _filters) _chip(status.label, status),
            ],
          ),
        ),
        fetch: (query, page) => ref
            .read(adminRemoteDataSourceProvider)
            .listVehicles(query: query, status: _status, page: page),
        itemBuilder: (context, vehicle) => _VehicleCard(
          vehicle: vehicle,
          onMaintenance: () => _sendToMaintenance(vehicle),
        ),
      ),
    );
  }

  Widget _chip(String label, AdminVehicleStatus? status) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _status == status,
      onSelected: (_) => setState(() => _status = status),
    ),
  );

  Future<void> _sendToMaintenance(AdminVehicle vehicle) async {
    final result = await showSendToMaintenanceSheet(context, vehicle);
    if (result == null || !mounted) return;
    // El camión cambió de estado: la lista se vuelve a pedir.
    await _list.currentState?.reload();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) =>
          _MaintenanceDoneDialog(plate: vehicle.displayPlate, result: result),
    );
  }
}

/// Tarjeta de un camión: placa, estado y la acción de mantenimiento.
class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onMaintenance});

  final AdminVehicle vehicle;
  final VoidCallback onMaintenance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inMaintenance = vehicle.status == AdminVehicleStatus.maintenance;
    final capacity = vehicle.capacityKg;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AnimatedAppIcon(AppIcon.deliver, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle.displayPlate,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusPill(vehicle.status.label, tone: _tone(vehicle.status)),
            ],
          ),
          if (capacity != null) ...[
            const SizedBox(height: 4),
            Text('Capacidad $capacity kg', style: theme.textTheme.bodyMedium),
          ],
          if (vehicle.fitToDispatch == false) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                vehicle.unfitReason == null
                    ? 'No apto para salir'
                    : 'No apto: ${vehicle.unfitReason}',
                tone: PillTone.danger,
                icon: AppIcon.incident,
              ),
            ),
          ],
          if (!inMaintenance) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onMaintenance,
              icon: const AnimatedAppIcon(
                AppIcon.settings,
                excludeFromSemantics: true,
              ),
              label: const Text('Mandar a mantenimiento'),
            ),
          ],
        ],
      ),
    );
  }

  static PillTone _tone(AdminVehicleStatus status) => switch (status) {
    AdminVehicleStatus.available => PillTone.success,
    AdminVehicleStatus.inService => PillTone.info,
    AdminVehicleStatus.maintenance => PillTone.warning,
    AdminVehicleStatus.inactive ||
    AdminVehicleStatus.unknown => PillTone.neutral,
  };
}

/// Confirmación tras mandar a mantenimiento: dice qué pasó con los pedidos
/// pendientes de su ruta (pasaron a otro camión, o quedaron sin camión y hay
/// que asignarlos).
class _MaintenanceDoneDialog extends StatelessWidget {
  const _MaintenanceDoneDialog({required this.plate, required this.result});

  final String plate;
  final MaintenanceResult result;

  @override
  Widget build(BuildContext context) {
    final moved = result.reassignedCount;
    final pending = result.pendingOrders;
    final withoutTruck = pending.length == 1
        ? 'Quedó 1 pedido SIN camión'
        : 'Quedaron ${pending.length} pedidos SIN camión';
    final lines = <String>[
      'Se abrió la orden de mantenimiento.',
      if (moved > 0)
        moved == 1
            ? '1 pedido pendiente pasó al otro camión.'
            : '$moved pedidos pendientes pasaron al otro camión.',
      if (pending.isNotEmpty)
        '$withoutTruck: asignalos desde Envíos.\n'
            '${pending.take(6).join(', ')}${pending.length > 6 ? '…' : ''}',
      if (moved == 0 && pending.isEmpty)
        'No tenía pedidos pendientes en su ruta de hoy.',
    ];
    return AlertDialog(
      title: Text('Camión $plate en mantenimiento'),
      content: Text(lines.join('\n\n')),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
