import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/api/models/destination.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/api/models/type3.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/layout/breakpoints.dart';

/// Texto humano del destino de una etiqueta (nombres, sin uuid):
/// "Domicilio · cliente · dirección", "Tienda nombre", "Almacén nombre".
/// `null` si no hay destino.
String? labelDestinationText(Destination? d) {
  if (d == null) return null;
  final name = d.name?.trim();
  final addr = d.address?.trim();
  final hasName = name != null && name.isNotEmpty;
  final hasAddr = addr != null && addr.isNotEmpty;
  switch (d.type) {
    case Type3.home:
      final parts = <String>[if (hasName) name, if (hasAddr) addr];
      return parts.isEmpty ? 'Domicilio' : 'Domicilio · ${parts.join(' · ')}';
    case Type3.store:
      return hasName ? 'Tienda $name' : 'Tienda';
    case Type3.warehouse:
      return hasName ? 'Almacén $name' : 'Almacén';
    default:
      if (hasName) return name;
      if (hasAddr) return addr;
      return null;
  }
}

/// Muestra un PREVIEW de la etiqueta de una unidad antes de imprimir (o solo
/// para verla). Dibuja la etiqueta como se ve en papel: fondo BLANCO con el QR
/// firmado real ([EmittedLabel.qrContent]), el nombre y SKU del producto, su
/// foto (si se conoce) y el destino/pedido. Desde acá se puede imprimir.
///
/// El QR se renderiza desde `qr_content` (el mismo payload firmado que va en la
/// etiqueta física), así el preview es fiel aunque el backend todavía no mande
/// una imagen renderizada de la etiqueta.
Future<void> showLabelPreviewSheet(
  BuildContext context, {
  required EmittedLabel label,
  String? productName,
  String? imageUrl,
  String? destination,
  Future<void> Function()? onPrint,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LabelPreviewSheet(
      label: label,
      productName: productName,
      imageUrl: imageUrl,
      destination: destination,
      onPrint: onPrint,
    ),
  );
}

class _LabelPreviewSheet extends StatefulWidget {
  const _LabelPreviewSheet({
    required this.label,
    required this.productName,
    required this.imageUrl,
    required this.destination,
    required this.onPrint,
  });

  final EmittedLabel label;
  final String? productName;
  final String? imageUrl;
  final String? destination;
  final Future<void> Function()? onPrint;

  @override
  State<_LabelPreviewSheet> createState() => _LabelPreviewSheetState();
}

class _LabelPreviewSheetState extends State<_LabelPreviewSheet> {
  bool _printing = false;

  Future<void> _print() async {
    final onPrint = widget.onPrint;
    if (onPrint == null || _printing) return;
    setState(() => _printing = true);
    try {
      await onPrint();
      if (mounted) await Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppBreakpoints.maxFormWidth,
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Etiqueta',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // La etiqueta, como en papel: SIEMPRE blanca (no sigue el
                      // tema oscuro de la app; una etiqueta impresa es blanca).
                      _LabelCard(
                        label: widget.label,
                        productName: widget.productName,
                        imageUrl: widget.imageUrl,
                        destination: widget.destination,
                      ),
                    ],
                  ),
                ),
              ),
              _Actions(
                canPrint: widget.onPrint != null,
                printing: _printing,
                onPrint: _print,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La etiqueta dibujada en blanco y negro, como sale de la Zebra.
class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.label,
    required this.productName,
    required this.imageUrl,
    required this.destination,
  });

  final EmittedLabel label;
  final String? productName;
  final String? imageUrl;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111111);
    final name = productName ?? 'Producto';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pedido + línea.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedido ${label.orderNumber}',
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                'Línea ${label.lineNumber}',
                style: const TextStyle(color: Color(0xFF555555), fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFDDDDDD)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: ResizeImage(
                      NetworkImage(imageUrl!),
                      width: 160,
                      height: 160,
                      policy: ResizeImagePolicy.fit,
                    ),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _NoPhoto(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU ${label.sku}',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (destination != null && destination!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Destino',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            Text(
              destination!,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // QR firmado real (el mismo que va impreso y verifica el chofer).
          Center(
            child: QrImageView(
              data: label.qrContent,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              // El QR en negro; sin puntos de más para que lea bien un lector
              // láser de gama baja.
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ink,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '…${_shortId(label.labelId)}',
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.length > 10 ? id.substring(id.length - 10) : id;
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const AnimatedAppIcon(
        AppIcon.receive,
        color: Color(0xFFAAAAAA),
        size: 24,
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.canPrint,
    required this.printing,
    required this.onPrint,
    required this.onClose,
  });

  final bool canPrint;
  final bool printing;
  final VoidCallback onPrint;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: printing ? null : onClose,
                child: const Text('Cerrar'),
              ),
            ),
            if (canPrint) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: printing ? null : onPrint,
                  icon: AnimatedAppIcon(
                    AppIcon.printing,
                    state: printing ? AppIconState.loading : AppIconState.idle,
                  ),
                  label: const Text('Imprimir'),
                ),
              ),
            ],
          ],
        ),
      ),
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
