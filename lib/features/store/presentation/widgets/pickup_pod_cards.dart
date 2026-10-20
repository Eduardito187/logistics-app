import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/store_controllers.dart';
import '../short_unit_id.dart';

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

/// Paso 1: confirmación del cliente (QR escaneado o documento escrito).
class PickupConfirmationCard extends StatelessWidget {
  const PickupConfirmationCard({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onScan,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '1 · Confirmación del cliente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined),
              labelText: 'QR del cliente o documento',
              hintText: 'Escanea o escribe la confirmación',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR del cliente'),
          ),
        ],
      ),
    );
  }
}

/// Paso 2: foto de entrega con su vista previa reducida.
class PickupPhotoCard extends StatelessWidget {
  const PickupPhotoCard({
    super.key,
    required this.photo,
    required this.busy,
    required this.onTakePhoto,
  });

  final File? photo;
  final bool busy;
  final VoidCallback onTakePhoto;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return SectionCard(
      title: '2 · Foto de entrega',
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
                  child: Center(child: Icon(Icons.image_outlined, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Offline invisible: la foto queda guardada y se sube sola.
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  'Foto guardada',
                  tone: PillTone.success,
                  icon: Icons.check_circle,
                ),
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: busy ? null : onTakePhoto,
            icon: const Icon(Icons.photo_camera),
            label: Text(photo == null ? 'Tomar foto' : 'Volver a tomar'),
          ),
        ],
      ),
    );
  }
}

/// Paso 3: bultos del envío con su estado (entregado/pendiente).
class PickupUnitsCard extends ConsumerWidget {
  const PickupUnitsCard({
    super.key,
    required this.shipmentId,
    required this.hasConfirmation,
    required this.delivered,
  });

  final String shipmentId;
  final bool hasConfirmation;

  /// IDs de bultos ya entregados en esta pantalla.
  final Set<String> delivered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(shipmentUnitsProvider(shipmentId));
    return SectionCard(
      title: '3 · Entregar bultos',
      child: AsyncValueView<List<UnitTracking>>(
        value: unitsAsync,
        onRetry: () => ref.invalidate(shipmentUnitsProvider(shipmentId)),
        data: (units) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasConfirmation)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Primero captura la confirmación del cliente.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              Text(
                'Entregados ${delivered.length} de ${units.length} bulto(s).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              for (final unit in units)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bulto ${unit.label ?? shortUnitId(unit.unitId)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (delivered.contains(unit.unitId))
                        const StatusPill(
                          'Entregado',
                          tone: PillTone.success,
                          icon: Icons.check_circle,
                        )
                      else
                        const StatusPill('Pendiente', tone: PillTone.neutral),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
