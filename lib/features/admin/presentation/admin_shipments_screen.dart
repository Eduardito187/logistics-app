import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/api/models/shipment_status.dart';
import '../../../core/icons/icons.dart';
import '../../../core/widgets/section_card.dart';
import '../../picking/presentation/widgets/shipment_status_pill.dart';
import '../data/admin_remote_data_source.dart';
import '../../../core/widgets/paged_search_list.dart';
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
  final TextEditingController _cityController = TextEditingController();
  Timer? _cityDebounce;

  /// Ciudad aplicada al filtro (ya recortada).
  String _city = '';

  /// `null` = todos los estados.
  ShipmentStatus? _status;

  static const List<(String, ShipmentStatus)> _filters = [
    ('Recibidos', ShipmentStatus.received),
    ('Planificados', ShipmentStatus.planned),
    ('En ruta', ShipmentStatus.inExecution),
    ('Entregados', ShipmentStatus.delivered),
    ('Fallidos', ShipmentStatus.failed),
  ];

  @override
  void dispose() {
    _cityDebounce?.cancel();
    _cityController.dispose();
    super.dispose();
  }

  void _onCityChanged(String text) {
    _cityDebounce?.cancel();
    _cityDebounce = Timer(const Duration(milliseconds: 350), () {
      final city = text.trim();
      if (city != _city && mounted) setState(() => _city = city);
    });
  }

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
            TextField(
              controller: _cityController,
              onChanged: _onCityChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                hintText: 'Santa Cruz, La Paz…',
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Todos', null),
                  for (final (label, status) in _filters) _chip(label, status),
                ],
              ),
            ),
          ],
        ),
        fetch: (query, page) => ref
            .read(adminRemoteDataSourceProvider)
            .listShipments(
              query: query,
              city: _city,
              status: _status,
              page: page,
            ),
        itemBuilder: (context, shipment) => _ShipmentCard(shipment: shipment),
      ),
    );
  }

  Widget _chip(String label, ShipmentStatus? status) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _status == status,
      onSelected: (_) => setState(() => _status = status),
    ),
  );
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
