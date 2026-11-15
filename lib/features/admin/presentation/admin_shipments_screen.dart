import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/department.dart';
import '../../../core/api/models/shipment.dart';
import '../../../core/api/models/shipment_status.dart';
import '../../../core/icons/icons.dart';
import '../../../core/widgets/section_card.dart';
import '../../picking/presentation/widgets/shipment_status_pill.dart';
import '../data/admin_remote_data_source.dart';
import '../../../core/widgets/paged_search_list.dart';
import 'staff_labels.dart';
import 'widgets/shipment_detail_sheet.dart';

/// Envíos de toda la operación para el administrador: buscar por código de
/// pedido o cliente, y filtrar por ciudad y estado.
class AdminShipmentsScreen extends ConsumerStatefulWidget {
  const AdminShipmentsScreen({super.key});

  @override
  ConsumerState<AdminShipmentsScreen> createState() =>
      _AdminShipmentsScreenState();
}

class _AdminShipmentsScreenState extends ConsumerState<AdminShipmentsScreen> {
  /// `null` = todas las ciudades.
  Department? _city;

  /// `null` = todos los estados.
  ShipmentStatus? _status;

  static const List<(String, ShipmentStatus)> _filters = [
    ('Recibidos', ShipmentStatus.received),
    ('Planificados', ShipmentStatus.planned),
    ('En ruta', ShipmentStatus.inExecution),
    ('Entregados', ShipmentStatus.delivered),
    ('Fallidos', ShipmentStatus.failed),
    ('Cancelados', ShipmentStatus.cancelled),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envíos')),
      body: PagedSearchList<Shipment>(
        searchLabel: 'Buscar envío',
        searchHint: 'Código de pedido, cliente o documento',
        emptyTitle: 'Sin envíos',
        emptyIcon: AppIcon.receive,
        // Ciudad + estado: al cambiar cualquiera, vuelve a la página 1.
        filterKey: (_city, _status),
        filters: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Department?>(
              value: _city,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ciudad'),
              items: [
                const DropdownMenuItem(child: Text('Todas las ciudades')),
                for (final department in staffDepartments)
                  DropdownMenuItem(
                    value: department,
                    child: Text(departmentLabel(department)),
                  ),
              ],
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ShipmentStatus?>(
              value: _status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: [
                const DropdownMenuItem(child: Text('Todos los estados')),
                for (final (label, status) in _filters)
                  DropdownMenuItem(value: status, child: Text(label)),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
          ],
        ),
        fetch: (query, page) => ref
            .read(adminRemoteDataSourceProvider)
            .listShipments(
              query: query,
              // Código del departamento: filtra por la ciudad de destino.
              city: _city?.json ?? '',
              status: _status,
              page: page,
            ),
        itemBuilder: (context, shipment) => _ShipmentCard(shipment: shipment),
      ),
    );
  }
}

/// Tarjeta de un envío: pedido, cliente, dirección y estado. Abre el detalle.
class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      onTap: () => showShipmentDetailSheet(context, shipment),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido ${shipment.externalId}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shipment.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  shipment.addressText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ShipmentStatusPill(shipment.status),
              ],
            ),
          ),
          const AnimatedAppIcon(
            AppIcon.chevronRight,
            excludeFromSemantics: true,
          ),
        ],
      ),
    );
  }
}
