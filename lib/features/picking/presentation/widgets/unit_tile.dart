import 'package:flutter/material.dart';

import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';

/// Miniatura del producto (foto decodificada chica) para la fila de la unidad.
/// Sin `imageUrl`, no ocupa espacio (el tile queda como antes).
class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});

  final String? imageUrl;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final cache = (_size * dpr).round();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image(
          image: ResizeImage(
            NetworkImage(url),
            width: cache,
            height: cache,
            policy: ResizeImagePolicy.fit,
          ),
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Fila de un producto del pedido: foto, nombre, SKU y estado. La acción
/// principal es simple: **Imprimir etiqueta** (la etiqueta ya existe, no hay que
/// escanear nada). El escaneo del producto queda como verificación OPCIONAL.
class UnitTile extends StatelessWidget {
  const UnitTile({
    super.key,
    required this.label,
    required this.prepared,
    required this.busy,
    required this.onPrint,
    this.onPreview,
  });

  final EmittedLabel label;
  final bool prepared;
  final bool busy;

  /// Imprime la etiqueta del producto (acción principal, un toque).
  final VoidCallback onPrint;

  /// Abre el PREVIEW de la etiqueta (verla / compartirla). `null` = no se ofrece.
  final VoidCallback? onPreview;

  /// Ancho de contenido por debajo del cual el estado va bajo el SKU.
  static const double _stackBelow = 340;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Con datos del backend (EmittedLabel enriquecido): el NOMBRE del
              // producto manda; SKU y línea quedan de subtítulo. Sin nombre, el
              // SKU es el título (compatibilidad).
              final name = label.productName;
              final hasName = name != null && name.isNotEmpty;
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasName ? name : label.sku,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasName
                        ? '${label.sku} · Línea ${label.lineNumber}'
                        : 'Línea ${label.lineNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              );
              final info = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductThumb(imageUrl: label.imageUrl),
                  Expanded(child: text),
                ],
              );
              final pill = prepared
                  ? const StatusPill(
                      'Preparado',
                      tone: PillTone.success,
                      icon: AppIcon.check,
                    )
                  : const StatusPill('Por preparar', icon: AppIcon.pending);
              // Angosto (teléfono chico, letra grande, columna de tablet): el
              // estado va debajo y el SKU usa todo el ancho.
              final preview = onPreview == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Ver etiqueta',
                      onPressed: onPreview,
                      icon: const AnimatedAppIcon(AppIcon.qrCode, size: 22),
                    );
              if (constraints.maxWidth < _stackBelow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: info),
                        preview,
                      ],
                    ),
                    const SizedBox(height: 8),
                    pill,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  preview,
                  const SizedBox(width: 4),
                  pill,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Acción principal, simple y directa: imprimir la etiqueta. No hace
          // falta escanear ni asignar nada; la etiqueta ya existe.
          FilledButton.icon(
            onPressed: busy ? null : onPrint,
            icon: AnimatedAppIcon(
              AppIcon.printing,
              state: busy ? AppIconState.loading : AppIconState.idle,
            ),
            label: Text(prepared ? 'Imprimir de nuevo' : 'Imprimir etiqueta'),
          ),
        ],
      ),
    );
  }
}
