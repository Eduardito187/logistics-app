import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/icons/icons.dart';
import '../../../../../core/layout/breakpoints.dart';
import '../../../../../core/map/map_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../core/widgets/tap_outside_to_dismiss.dart';
import '../../../data/datasources/delivery_evidence_data_source.dart';
import '../../../domain/entities/delivery_evidence.dart';
import '../../../../../core/widgets/brand_loader.dart';
import '../../../domain/entities/street_address.dart';
import '../../controllers/driver_controllers.dart';
import 'delivery_contact.dart';

/// `true` si a la parada le falta teléfono, dirección o productos y hay que
/// completarla con el detalle del envío (`GET /shipments/{id}`).
bool stopNeedsShipmentDetail(DriverRouteStop stop) =>
    (stop.customerPhone?.isEmpty ?? true) ||
    (stop.address?.isEmpty ?? true) ||
    stop.items.isEmpty;

/// Abre los DATOS de la entrega (cliente, teléfono y dirección como enlaces
/// tocables, referencia del pedido y los productos con SKU/cantidad) en un
/// modal BAJO DEMANDA. Antes esto vivía como una hoja SIEMPRE visible que
/// tapaba medio mapa; ahora el mapa manda y el detalle se abre solo cuando el
/// chofer lo pide (desde "Ver pedido" en la barra de acciones) y se cierra
/// deslizando hacia abajo o tocando fuera.
///
/// La altura es DINÁMICA: el modal mide lo que mide su contenido (pocos
/// productos → bajo, sin espacio vacío; muchos → crece hasta 90% y recién ahí
/// hace scroll interno). Así se adapta a 1 o a varios ítems.
Future<void> showDeliveryDetailsSheet(
  BuildContext context,
  DriverRouteStop stop,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
      return TapOutsideToDismiss(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
            maxHeight: maxHeight,
          ),
          child: Material(
            color: theme.colorScheme.surface,
            elevation: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Grabber(),
                // Flexible + SingleChildScrollView: el contenido define el alto
                // (ajuste exacto) y, si supera el tope, recién ahí hay scroll.
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                        _EvidenceSection(stop: stop),
                      ],
                    ),
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

/// Evidencia del cliente (firma / documento / foto) con su estado de validación
/// anti-fraude. Solo aparece si el envío ya tiene evidencia subida. Para el
/// chofer: si el documento "No coincide", conviene volver a tomarlo.
class _EvidenceSection extends ConsumerWidget {
  const _EvidenceSection({required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(deliveryEvidenceProvider(stop.shipmentId)).value ??
        const <DeliveryEvidenceItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidencia del cliente',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(_kindLabel(e.kind))),
                  const SizedBox(width: 12),
                  _validationPill(e.status),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _kindLabel(String kind) => switch (kind) {
    'signature' => 'Firma del cliente',
    'id_document' => 'Documento del cliente',
    'damage' => 'Foto de daño',
    _ => 'Foto de entrega',
  };

  static Widget _validationPill(EvidenceValidation status) => switch (status) {
    EvidenceValidation.ok => const StatusPill(
      'Validado',
      tone: PillTone.success,
      icon: AppIcon.check,
    ),
    EvidenceValidation.review => const StatusPill(
      'Revisar',
      tone: PillTone.warning,
      icon: AppIcon.pending,
    ),
    EvidenceValidation.mismatch => const StatusPill(
      'No coincide',
      tone: PillTone.danger,
      icon: AppIcon.cancel,
    ),
    _ => const StatusPill('Validando…', icon: AppIcon.pending),
  };
}

/// Cliente, teléfono (con llamar) y dirección (con navegar). El teléfono sale
/// del detalle del envío; si no llega, la fila no se muestra.
class _DeliveryDetails extends ConsumerWidget {
  const _DeliveryDetails({required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La parada ya trae teléfono e indicaciones; el detalle del envío es el
    // respaldo (rutas cacheadas de una versión anterior del backend) y SOLO se
    // pide si a la parada le falta algo: sin request extra por parada.
    final shipment = stopNeedsShipmentDetail(stop)
        ? ref.watch(shipmentDetailProvider(stop.shipmentId)).value
        : null;
    final name = stop.customerName ?? shipment?.customerName ?? 'Cliente';
    final phone = stop.customerPhone ?? shipment?.customerPhone;
    final rawAddress = stop.address ?? shipment?.addressText;
    final address = rawAddress == null ? null : streetAddress(rawAddress);
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
          // El teléfono ES el enlace (tocar = llamar): sin botón "Llamar"
          // aparte, el número ocupa todo el ancho y se lee mejor.
          _DetailRow(
            leading: const AnimatedAppIcon(AppIcon.call, size: 26),
            label: 'Teléfono · toca para llamar',
            value: phone,
            onTap: () => unawaited(dialPhone(phone)),
          ),
        if (address != null && address.isNotEmpty)
          // La dirección ES el enlace (tocar = navegar): sin botón "Navegar"
          // al lado, usa todo el ancho y se corta en menos líneas.
          _DetailRow(
            leading: const AnimatedAppIcon(AppIcon.place, size: 26),
            label: stop.lat != null && stop.lng != null
                ? 'Entregar en · toca para navegar'
                : 'Entregar en',
            value: note == null || note.isEmpty ? address : '$address\n$note',
            dense: true,
            onTap: stop.lat != null && stop.lng != null
                ? () => unawaited(
                    openExternalNavigation(stop.lat!, stop.lng!, label: name),
                  )
                : null,
          ),
      ],
    );
  }

  static final RegExp _spaces = RegExp(r'\s+');

  static String _initials(String name) {
    final parts = name.trim().split(_spaces).where((p) => p.isNotEmpty).take(2);
    final initials = parts.map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}

/// Fila de dato de la entrega: ícono + etiqueta + valor. Si [onTap] no es nulo,
/// el VALOR es un enlace (color de marca, tocable): el teléfono llama y la
/// dirección navega, sin botones aparte (así el valor usa todo el ancho). Toda
/// la fila es tocable para un objetivo cómodo.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.leading,
    required this.label,
    required this.value,
    this.onTap,
    this.dense = false,
  });

  final Widget leading;
  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Texto del valor más chico (filas largas como la dirección).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = onTap != null;
    final valueStyle =
        (dense ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium)
            ?.copyWith(
              fontWeight: FontWeight.w700,
              // Enlace: color de marca (no el ámbar, reservado a alertas).
              color: link ? AppColors.brand : null,
            );

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 48, child: Center(child: leading)),
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
                const SizedBox(height: 2),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );

    if (!link) return content;
    return Semantics(
      button: true,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

/// Productos del pedido: foto, nombre, SKU y cantidad. Salen de la parada
/// (`items`); si vienen vacíos, del detalle del envío.
///
/// Va como una COLUMNA (no sliver) para que el modal mida exactamente lo que
/// mide el pedido: un envío típico tiene pocos productos, así que no vale la
/// pena una lista perezosa con alto fijo (dejaba espacio vacío); si llegara a
/// traer muchos, el scroll del modal los contiene.
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

    final Widget body;
    if (items.isEmpty && detail != null && detail.isLoading) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: BrandLoader()),
      );
    } else if (items.isEmpty && detail != null && detail.hasError) {
      body = Row(
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
      );
    } else if (items.isEmpty) {
      body = const Text('El pedido no tiene productos detallados.');
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final item in items) ProductTile(item: item)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
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
        ),
        body,
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
    final placeholder = AnimatedAppIcon(
      AppIcon.receive,
      color: theme.colorScheme.outline,
    );
    final url = item.imageUrl;
    // Se decodifica al tamaño físico real del thumb (lógico × DPR del equipo,
    // acotado 1–3). En los Go de 512 MB (DPR 1.5–2) esto decodifica ~1,5× menos
    // que el ×3 fijo anterior, sin verse borroso en pantallas de alta densidad.
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final cache = (_size * dpr).round();
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
                // `fit`: se decodifica dentro de cache x cache SIN deformar
                // (con ancho y alto fijos una foto 4:3 quedaba aplastada).
                : Image(
                    image: ResizeImage(
                      NetworkImage(url),
                      width: cache,
                      height: cache,
                      policy: ResizeImagePolicy.fit,
                    ),
                    fit: BoxFit.cover,
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
                  item.sku,
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
