import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/unit_product.dart';
import '../controllers/shelf_locations_notifier.dart';
import '../short_unit_id.dart';
import 'sliver_section_card.dart';

/// Lista de productos del manifiesto (uno por unidad física) con foto, nombre,
/// código, su estado y la ubicación en estante.
///
/// Es un SLIVER (va dentro de un `CustomScrollView`): las filas se construyen
/// a demanda, así un manifiesto de 100+ productos con foto solo decodifica las
/// miniaturas visibles en vez de todas.
class ReceptionUnitsCard extends StatelessWidget {
  const ReceptionUnitsCard({
    super.key,
    required this.expected,
    required this.received,
    required this.surplus,
    this.products = const {},
  });

  final List<String> expected;
  final Set<String> received;
  final Set<String> surplus;

  /// Producto de cada unidad, por id de unidad. Sin dato se muestra genérico.
  final Map<String, UnitProduct> products;

  @override
  Widget build(BuildContext context) {
    // Sobrantes indexables sin copiar la lista de esperados.
    final surplusList = surplus.toList(growable: false);
    final count = expected.length + surplusList.length;
    return SliverSectionCard(
      title: 'Productos',
      sliver: SliverList.builder(
        itemCount: count,
        itemBuilder: (context, index) {
          final isSurplus = index >= expected.length;
          final id = isSurplus
              ? surplusList[index - expected.length]
              : expected[index];
          return _ShelfAwareRow(
            key: ValueKey(id),
            unitId: id,
            product: products[id],
            status: isSurplus
                ? UnitRowStatus.surplus
                : received.contains(id)
                ? UnitRowStatus.received
                : UnitRowStatus.pending,
          );
        },
      ),
    );
  }
}

/// Fila que escucha SOLO la ubicación en estante de su bulto: guardar una
/// ubicación reconstruye esa fila y no la lista entera.
class _ShelfAwareRow extends ConsumerWidget {
  const _ShelfAwareRow({
    super.key,
    required this.unitId,
    required this.product,
    required this.status,
  });

  final String unitId;
  final UnitProduct? product;
  final UnitRowStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(shelfLocationsProvider.select((m) => m[unitId]));
    return UnitProductRow(
      unitId: unitId,
      product: product,
      status: status,
      shelf: shelf,
    );
  }
}

/// Estado de una unidad en una lista de la tienda.
enum UnitRowStatus { pending, received, surplus, delivered }

/// Fila de producto: foto chica (decodificada al tamaño de la miniatura para
/// no gastar RAM), nombre, código y pieza; a la derecha el estado.
class UnitProductRow extends StatelessWidget {
  const UnitProductRow({
    super.key,
    required this.unitId,
    required this.product,
    required this.status,
    this.shelf,
  });

  final String unitId;
  final UnitProduct? product;
  final UnitRowStatus status;
  final String? shelf;

  static const double _thumb = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (String text, PillTone tone, IconData icon) = switch (status) {
      UnitRowStatus.surplus => (
        'Sobrante',
        PillTone.danger,
        Icons.report_gmailerrorred,
      ),
      UnitRowStatus.received => (
        'Recibido',
        PillTone.success,
        Icons.check_circle,
      ),
      UnitRowStatus.delivered => (
        'Entregado',
        PillTone.success,
        Icons.check_circle,
      ),
      UnitRowStatus.pending => (
        'Pendiente',
        PillTone.neutral,
        Icons.radio_button_unchecked,
      ),
    };
    final name = product?.name;
    final sku = product?.sku;
    final piece = product?.pieceLabel;
    final subtitle = [?sku, ?piece, if (shelf != null) 'Estante: $shelf'];
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _Thumb(url: product?.imageUrl, size: _thumb, label: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Producto ${shortUnitId(unitId)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // En teléfonos chicos con letra grande la pastilla se achica en vez
          // de desbordar la fila.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StatusPill(text, tone: tone, icon: icon),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.size, this.label});

  final String? url;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Icon(
      Icons.inventory_2_outlined,
      color: theme.colorScheme.outline,
    );
    // Decodificada al tamaño real en pantalla (dp x densidad, tope 3x): una
    // foto de catálogo de 1000+ px pesa ~4 MB decodificada; así ~80 KB.
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final cache = (size * dpr).round();
    final src = url;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: src == null || src.isEmpty
          ? placeholder
          : Image.network(
              src,
              fit: BoxFit.cover,
              cacheWidth: cache,
              cacheHeight: cache,
              semanticLabel: label,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
