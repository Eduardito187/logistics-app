import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/layout/breakpoints.dart';
import '../../../../../core/map/map_launcher.dart';
import '../../controllers/driver_controllers.dart';
import 'delivery_contact.dart';

/// Hoja deslizable sobre el mapa con los datos de la entrega (cliente,
/// teléfono, dirección, referencia del pedido) y el pedido (productos con SKU y
/// cantidad). Arranca a media altura; se arrastra para ver todo.
class DeliverySheet extends StatelessWidget {
  const DeliverySheet({super.key, required this.stop});

  final DriverRouteStop stop;

  static const double minSize = 0.30;
  static const double initialSize = 0.42;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: minSize,
      initialChildSize: initialSize,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [initialSize],
      builder: (context, controller) {
        final theme = Theme.of(context);
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Material(
              color: theme.colorScheme.surface,
              elevation: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  const SliverToBoxAdapter(child: _Grabber()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          'Entrega',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DeliveryDetails(stop: stop),
                        const SizedBox(height: 20),
                        _OrderSection(stop: stop),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Cliente, teléfono (con llamar) y dirección (con navegar). El teléfono sale
/// del detalle del envío; si no llega, la fila no se muestra.
class _DeliveryDetails extends ConsumerWidget {
  const _DeliveryDetails({required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La parada ya trae teléfono e indicaciones; el detalle del envío es el
    // respaldo (rutas cacheadas de una versión anterior del backend).
    final shipment = ref.watch(shipmentDetailProvider(stop.shipmentId)).value;
    final name = stop.customerName ?? shipment?.customerName ?? 'Cliente';
    final phone = stop.customerPhone ?? shipment?.customerPhone;
    final address = stop.address ?? shipment?.addressText;
    final reference = stop.orderReference ?? shipment?.externalId;
    final note = stop.addressReference ?? shipment?.addressReference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(
          leading: CircleAvatar(
            radius: 26,
            child: Text(
              _initials(name),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          label: reference == null ? 'Cliente' : 'Cliente · Pedido $reference',
          value: name,
        ),
        if (phone != null && phone.isNotEmpty)
          _DetailRow(
            leading: const Icon(Icons.phone, size: 28),
            label: 'Teléfono',
            value: phone,
            action: _RowAction(
              label: 'Llamar',
              icon: Icons.call,
              onPressed: () => unawaited(dialPhone(phone)),
            ),
          ),
        if (address != null && address.isNotEmpty)
          _DetailRow(
            leading: const Icon(Icons.location_on_outlined, size: 28),
            label: 'Entregar en',
            value: note == null || note.isEmpty ? address : '$address\n$note',
            action: stop.lat != null && stop.lng != null
                ? _RowAction(
                    label: 'Navegar',
                    icon: Icons.navigation,
                    onPressed: () => unawaited(
                      openExternalNavigation(stop.lat!, stop.lng!, label: name),
                    ),
                  )
                : null,
          ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    final initials = parts.map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}

class _RowAction {
  const _RowAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.leading,
    required this.label,
    required this.value,
    this.action,
  });

  final Widget leading;
  final String label;
  final String value;
  final _RowAction? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 52, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            TextButton.icon(
              onPressed: action!.onPressed,
              icon: Icon(action!.icon),
              label: Text(action!.label),
            ),
        ],
      ),
    );
  }
}

/// Productos del pedido: foto, nombre, SKU y cantidad. Salen de la parada
/// (`items`); si vienen vacíos, del detalle del envío.
class _OrderSection extends ConsumerWidget {
  const _OrderSection({required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fromStop = stop.items
        .map(
          (i) => OrderItemView(
            sku: i.sku,
            name: i.name,
            quantity: i.quantity,
            imageUrl: i.imageUrl,
          ),
        )
        .toList(growable: false);
    final detail = fromStop.isEmpty
        ? ref.watch(shipmentDetailProvider(stop.shipmentId))
        : null;
    final items = fromStop.isNotEmpty
        ? fromStop
        : (detail?.value?.lines ?? const <ShipmentLine>[])
              .map(
                (l) => OrderItemView(
                  sku: l.sku,
                  name: l.productName,
                  quantity: l.quantity,
                  imageUrl: l.imageUrl,
                ),
              )
              .toList(growable: false);
    final units = items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pedido',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (items.isNotEmpty)
              Text(
                units == 1 ? '1 producto' : '$units productos',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty && detail != null && detail.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty && detail != null && detail.hasError)
          Row(
            children: [
              const Expanded(
                child: Text('No se pudo cargar el detalle del pedido.'),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(shipmentDetailProvider(stop.shipmentId)),
                child: const Text('Reintentar'),
              ),
            ],
          )
        else if (items.isEmpty)
          const Text('El pedido no tiene productos detallados.')
        else
          for (final item in items) ProductTile(item: item),
      ],
    );
  }
}

/// Producto a mostrar, venga de la parada o de las líneas del envío.
class OrderItemView {
  const OrderItemView({
    required this.sku,
    required this.name,
    required this.quantity,
    this.imageUrl,
  });

  final String sku;
  final String name;
  final int quantity;
  final String? imageUrl;
}

/// Fila de producto: foto (decodificada chica para no gastar RAM), nombre, SKU
/// y cantidad. Sin foto o si falla la descarga, un ícono del mismo tamaño.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.item});

  final OrderItemView item;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Icon(
      Icons.inventory_2_outlined,
      color: theme.colorScheme.outline,
    );
    final url = item.imageUrl;
    // ~3x el tamaño lógico alcanza para pantallas de alta densidad.
    final cache = (_size * 3).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: _size,
            height: _size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: url == null || url.isEmpty
                ? placeholder
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    cacheWidth: cache,
                    cacheHeight: cache,
                    semanticLabel: item.name,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'SKU ${item.sku}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x${item.quantity}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
