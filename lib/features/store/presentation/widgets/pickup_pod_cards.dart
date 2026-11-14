import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
// La firma y la vista previa de evidencia son las MISMAS piezas de la entrega
// del chofer (mismo proceso, pedido del dueño): se reutilizan, no se duplican.
import '../../../driver/presentation/widgets/evidence_photo_preview.dart';
import '../../domain/entities/unit_product.dart';
import '../controllers/store_controllers.dart';
import 'reception_units_card.dart';
import 'sliver_section_card.dart';

/// Ancho (px) al que se decodifica la vista previa de la foto: alcanza para la
/// miniatura de 160 dp de alto y evita decodificar la foto entera (1600 px).
const int kPhotoPreviewCacheWidth = 800;

/// Datos del cliente que retira en mostrador.
class PickupCustomerCard extends StatelessWidget {
  const PickupCustomerCard({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shipment.customerName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pedido ${shipment.externalId}',
            style: theme.textTheme.bodyMedium,
          ),
          if (shipment.customerDocumentId != null)
            Text(
              'Documento: ${shipment.customerDocumentId}',
              style: theme.textTheme.bodySmall,
            ),
          if (shipment.customerPhone != null)
            Text(
              'Teléfono: ${shipment.customerPhone}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// Paso 1: firma del cliente en pantalla (igual que la entrega del chofer).
class PickupSignatureCard extends StatelessWidget {
  const PickupSignatureCard({
    super.key,
    required this.signature,
    required this.busy,
    required this.onSign,
  });

  /// PNG de la firma, o `null` si el cliente todavía no firmó.
  final Uint8List? signature;
  final bool busy;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) {
    final signature = this.signature;
    return SectionCard(
      title: '1 · Firma del cliente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (signature != null) ...[
            const Text('Firmado por el cliente.'),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: SignaturePreview(
                key: const ValueKey('signature-preview'),
                png: signature,
              ),
            ),
          ] else
            const Text('Pedile al cliente que firme.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onSign,
            icon: const AnimatedAppIcon(
              AppIcon.signature,
              excludeFromSemantics: true,
            ),
            label: Text(
              signature == null ? 'Firma del cliente' : 'Volver a firmar',
            ),
          ),
        ],
      ),
    );
  }
}

/// Paso 3: foto del documento (carnet) del cliente. Opcional.
class PickupDocumentCard extends StatelessWidget {
  const PickupDocumentCard({
    super.key,
    required this.document,
    required this.busy,
    required this.onTakeDocument,
  });

  final File? document;
  final bool busy;
  final VoidCallback onTakeDocument;

  @override
  Widget build(BuildContext context) {
    final document = this.document;
    return SectionCard(
      title: '3 · Documento del cliente (opcional)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (document != null) ...[
            EvidencePhotoPreview(path: document.path),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: busy ? null : onTakeDocument,
            icon: const AnimatedAppIcon(
              AppIcon.capture,
              excludeFromSemantics: true,
            ),
            label: Text(
              document == null ? 'Foto del documento' : 'Volver a tomar documento',
            ),
          ),
        ],
      ),
    );
  }
}

/// Paso 2: foto de entrega (obligatoria) con su vista previa reducida.
class PickupPhotoCard extends StatelessWidget {
  const PickupPhotoCard({
    super.key,
    required this.photo,
    required this.busy,
    required this.onTakePhoto,
    this.onShare,
  });

  final File? photo;
  final bool busy;
  final VoidCallback onTakePhoto;

  /// Comparte la foto por el menú nativo (WhatsApp, etc.). `null` = sin botón.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return SectionCard(
      title: '2 · Foto de entrega (obligatoria)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                photo,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                // Se decodifica reducida: la foto completa en memoria pesa
                // decenas de MB y en teléfonos de 1 GB puede cerrar la app.
                cacheWidth: kPhotoPreviewCacheWidth,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 160,
                  child: Center(
                    child: AnimatedAppIcon(
                      AppIcon.image,
                      size: 48,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Offline invisible: la foto queda guardada y se sube sola.
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const StatusPill(
                    'Foto guardada',
                    tone: PillTone.success,
                    icon: AppIcon.success,
                    // El check se dibuja con pop cuando la foto queda guardada.
                    iconState: AppIconState.success,
                  ),
                  const Spacer(),
                  if (onShare != null)
                    TextButton.icon(
                      onPressed: busy ? null : onShare,
                      icon: const AnimatedAppIcon(AppIcon.send, size: 18),
                      label: const Text('Compartir'),
                    ),
                ],
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: busy ? null : onTakePhoto,
            icon: const AnimatedAppIcon(
              AppIcon.capture,
              excludeFromSemantics: true,
            ),
            label: Text(photo == null ? 'Tomar foto' : 'Volver a tomar'),
          ),
        ],
      ),
    );
  }
}

/// Paso 4: productos del pedido (foto, nombre, SKU, código de etiqueta) con su
/// estado (entregado / escaneado / pendiente). Con eso el personal de tienda
/// ubica cada producto en su almacén antes de escanearlo.
///
/// Es un SLIVER (va dentro de un `CustomScrollView`): las filas se construyen a
/// demanda y solo se decodifican las fotos visibles, aunque el pedido traiga
/// 100+ productos.
class PickupUnitsCard extends ConsumerWidget {
  const PickupUnitsCard({
    super.key,
    required this.shipmentId,
    required this.scanned,
    required this.delivered,
  });

  final String shipmentId;

  /// IDs de productos escaneados en esta pantalla, todavía sin registrar.
  final Set<String> scanned;

  /// IDs de productos ya entregados (confirmados o registrados acá).
  final Set<String> delivered;

  static const String _title = '4 · Productos del pedido';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(shipmentUnitsProvider(shipmentId));
    final units = unitsAsync.hasError ? null : unitsAsync.value;
    if (units == null) {
      // Cargando o error: tarjeta común con el estado y "Reintentar".
      return SliverToBoxAdapter(
        child: SectionCard(
          title: _title,
          child: AsyncValueView<List<UnitTracking>>(
            value: unitsAsync,
            onRetry: () => ref.invalidate(shipmentUnitsProvider(shipmentId)),
            data: (_) => const SizedBox.shrink(),
          ),
        ),
      );
    }
    return SliverSectionCard(
      title: _title,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Entregados ${delivered.length} de ${units.length} producto(s).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (scanned.isNotEmpty)
            Text(
              'Escaneados para entregar: ${scanned.length}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 8),
        ],
      ),
      sliver: SliverList.builder(
        itemCount: units.length,
        itemBuilder: (context, index) {
          final unit = units[index];
          return UnitProductRow(
            key: ValueKey(unit.unitId),
            unitId: unit.unitId,
            product: trackingProduct(unit),
            showLabelCode: true,
            status: delivered.contains(unit.unitId)
                ? UnitRowStatus.delivered
                : scanned.contains(unit.unitId)
                ? UnitRowStatus.scanned
                : UnitRowStatus.pending,
          );
        },
      ),
    );
  }
}
