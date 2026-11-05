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

/// Fila de una unidad del pedido: SKU, bulto y estado, con la acción de escanear
/// e imprimir (si está pendiente) o reimprimir (si ya está preparada).
class UnitTile extends StatelessWidget {
  const UnitTile({
    super.key,
    required this.label,
    required this.prepared,
    required this.busy,
    required this.onPrepare,
    required this.onReprint,
    this.onPreview,
  });

  final EmittedLabel label;
  final bool prepared;
  final bool busy;
  final VoidCallback onPrepare;
  final VoidCallback onReprint;

  /// Abre el PREVIEW de la etiqueta (verla antes de imprimir). Si es `null`, no
  /// se muestra la acción.
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
                    hasName ? name : 'SKU ${label.sku}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasName
                        ? 'SKU ${label.sku} · Línea ${label.lineNumber}'
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
                      'Preparada',
                      tone: PillTone.success,
                      icon: AppIcon.check,
                    )
                  : const StatusPill('Pendiente', icon: AppIcon.pending);
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
          if (prepared)
            OutlinedButton.icon(
              onPressed: busy ? null : onReprint,
              // Mientras reimprime, la hoja sale de la impresora.
              icon: AnimatedAppIcon(
                AppIcon.printing,
                state: busy ? AppIconState.loading : AppIconState.idle,
              ),
              label: const Text('Reimprimir etiqueta'),
            )
          else
            FilledButton.icon(
              onPressed: busy ? null : onPrepare,
              // Mientras registra el escaneo, el láser barre el marco.
              icon: AnimatedAppIcon(
                AppIcon.scan,
                state: busy ? AppIconState.loading : AppIconState.idle,
              ),
              label: const Text('Escanear EAN e imprimir'),
            ),
        ],
      ),
    );
  }
}
