import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/dispatch_line.dart';
import '../../../../core/api/models/dispatch_line_label_status.dart';
import '../../../../core/api/models/dispatch_lines_response.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/order_labels_controller.dart';
import 'label_preview_sheet.dart';

/// Lista SIMPLE de productos a etiquetar de un pedido (desde dispatch-lines): el
/// pedido ya trae cada producto con nombre, SKU, foto y su DESTINO (domicilio,
/// tienda o almacén) resueltos — nada de cargar origen/destino a mano. Agrupada
/// por destino/envío (soporta multishipping n-a-n: un producto a un domicilio,
/// otro a una tienda). Cada producto emitido tiene "Ver etiqueta" (preview); si
/// la línea no está autorizada, se avisa el motivo.
class DispatchLinesBody extends ConsumerWidget {
  const DispatchLinesBody({
    super.key,
    required this.orderNumber,
    required this.onEmit,
    required this.busy,
  });

  final String orderNumber;

  /// Emite el lote de etiquetas del pedido (flujo existente).
  final VoidCallback onEmit;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linesAsync = ref.watch(orderDispatchLinesProvider(orderNumber));
    // Las etiquetas ya emitidas, para ofrecer el preview por producto (el QR
    // vive en EmittedLabel, no en dispatch-lines).
    final labels =
        ref.watch(orderLabelsProvider(orderNumber)).value ??
        const <EmittedLabel>[];
    final labelBySkuLine = <String, EmittedLabel>{
      for (final l in labels) '${l.sku}|${l.lineNumber}': l,
    };

    return AsyncValueView<DispatchLinesResponse>(
      value: linesAsync,
      onRetry: () => ref.invalidate(orderDispatchLinesProvider(orderNumber)),
      data: (res) {
        if (res.data.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(orderDispatchLinesProvider(orderNumber)),
            child: ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('El pedido no tiene productos para etiquetar.'),
                  ),
                ),
              ],
            ),
          );
        }
        // Agrupar por envío (destino). Hoy suele ser un solo grupo; con
        // multishipping real vienen varios.
        final groups = <String?, List<DispatchLine>>{};
        for (final line in res.data) {
          groups.putIfAbsent(line.shipmentId, () => []).add(line);
        }
        final pendingAuthorized = res.data.any(
          (l) =>
              l.authorized && l.labelStatus == DispatchLineLabelStatus.pending,
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(orderDispatchLinesProvider(orderNumber))
              ..invalidate(orderLabelsProvider(orderNumber));
          },
          child: ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final entry in groups.entries) ...[
                  _GroupHeader(lines: entry.value),
                  const SizedBox(height: 8),
                  for (final line in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DispatchLineCard(
                        line: line,
                        label: labelBySkuLine['${line.sku}|${line.lineNumber}'],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                if (pendingAuthorized) ...[
                  const SizedBox(height: 4),
                  // Botón plano (no `.icon`): la fila llena el ancho y el texto
                  // va en `Flexible`, así en teléfonos chicos con letra grande
                  // se ajusta en 2 líneas en vez de desbordar.
                  FilledButton(
                    onPressed: busy ? null : onEmit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedAppIcon(
                          AppIcon.printing,
                          state: busy
                              ? AppIconState.loading
                              : AppIconState.idle,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Emitir etiquetas del pedido',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cabecera de un grupo (un envío/destino) con el destino y cuántos productos.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.lines});

  final List<DispatchLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dest = dispatchDestinationText(lines.first.destination) ?? 'Destino';
    final reference = lines.first.shipmentReference;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnimatedAppIcon(AppIcon.place, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dest,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  reference == null
                      ? '${lines.length} producto(s)'
                      : 'Envío $reference · ${lines.length} producto(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de un producto a etiquetar: foto, nombre, SKU, cantidad y estado.
/// Emitido → "Ver etiqueta" (preview). No autorizado → aviso del motivo.
class _DispatchLineCard extends StatelessWidget {
  const _DispatchLineCard({required this.line, required this.label});

  final DispatchLine line;
  final EmittedLabel? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = line.productName;
    final hasName = name != null && name.isNotEmpty;
    final emitted = line.labelStatus == DispatchLineLabelStatus.emitted;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(imageUrl: line.imageUrl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasName ? name : line.sku,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${line.sku} · x${line.quantity} · Línea ${line.lineNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // El estado va en su propia línea (no compite con el nombre): en
          // teléfonos chicos con letra grande nunca desborda la fila.
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusPill(line: line),
          ),
          if (!line.authorized) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const AnimatedAppIcon(
                  AppIcon.error,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.authorizedReason ?? 'Sin autorizar para etiquetar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (emitted && label != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => showLabelPreviewSheet(
                context,
                label: label!,
                productName: line.productName,
                imageUrl: line.imageUrl,
                destination: dispatchDestinationText(line.destination),
              ),
              icon: const AnimatedAppIcon(AppIcon.qrCode),
              label: const Text('Ver etiqueta'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.line});

  final DispatchLine line;

  @override
  Widget build(BuildContext context) {
    if (!line.authorized) {
      return const StatusPill(
        'Sin autorizar',
        tone: PillTone.danger,
        icon: AppIcon.cancel,
      );
    }
    return switch (line.labelStatus) {
      DispatchLineLabelStatus.emitted => const StatusPill(
        'Etiqueta lista',
        tone: PillTone.success,
        icon: AppIcon.check,
      ),
      DispatchLineLabelStatus.revoked => const StatusPill(
        'Revocada',
        tone: PillTone.danger,
        icon: AppIcon.cancel,
      ),
      _ => const StatusPill('Por etiquetar', icon: AppIcon.pending),
    };
  }
}

/// Miniatura del producto (foto decodificada chica). Sin URL, no ocupa espacio.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String? imageUrl;

  static const double _size = 48;

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
