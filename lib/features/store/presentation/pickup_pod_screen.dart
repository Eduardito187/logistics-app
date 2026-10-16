import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/api/models/unit_tracking.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/sync_badge.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import '../domain/usecases/record_pod.dart';
import 'controllers/store_controllers.dart';
import 'short_unit_id.dart';
import 'unit_scan.dart';

/// Prueba de entrega en mostrador (recojo en tienda): se confirma al cliente,
/// se toma una foto como evidencia y se registra el POD por cada bulto retirado.
class PickupPodScreen extends ConsumerStatefulWidget {
  const PickupPodScreen({super.key, required this.shipment});

  final Shipment shipment;

  @override
  ConsumerState<PickupPodScreen> createState() => _PickupPodScreenState();
}

class _PickupPodScreenState extends ConsumerState<PickupPodScreen> {
  final TextEditingController _confirmationController = TextEditingController();
  File? _photoFile;
  String? _photoPath;
  bool _uploadingPhoto = false;
  bool _busy = false;
  final Set<String> _delivered = <String>{};

  Shipment get _shipment => widget.shipment;

  bool get _hasConfirmation => _confirmationController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega en mostrador'),
        actions: [
          SyncBadge(onTap: () => context.push('/sync')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _customerCard(context),
          const SizedBox(height: 16),
          _confirmationCard(context),
          const SizedBox(height: 16),
          _photoCard(context),
          const SizedBox(height: 16),
          _unitsCard(context),
        ],
      ),
    );
  }

  Widget _customerCard(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shipment.customerName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pedido ${_shipment.externalId}',
            style: theme.textTheme.bodyMedium,
          ),
          if (_shipment.customerDocumentId != null)
            Text(
              'Documento: ${_shipment.customerDocumentId}',
              style: theme.textTheme.bodySmall,
            ),
          if (_shipment.customerPhone != null)
            Text(
              'Teléfono: ${_shipment.customerPhone}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _confirmationCard(BuildContext context) {
    return SectionCard(
      title: '1 · Confirmación del cliente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _confirmationController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined),
              labelText: 'QR del cliente o documento',
              hintText: 'Escanea o escribe la confirmación',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _scanConfirmation,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR del cliente'),
          ),
        ],
      ),
    );
  }

  Widget _photoCard(BuildContext context) {
    return SectionCard(
      title: '2 · Foto de entrega',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_photoFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _photoFile!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (_photoFile != null) const SizedBox(height: 8),
          if (_uploadingPhoto)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Subiendo foto…'),
                ],
              ),
            )
          else if (_photoFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StatusPill(
                _photoPath != null ? 'Foto subida' : 'Foto pendiente de subir',
                tone: _photoPath != null ? PillTone.success : PillTone.warning,
                icon: _photoPath != null
                    ? Icons.cloud_done
                    : Icons.cloud_upload_outlined,
              ),
            ),
          OutlinedButton.icon(
            onPressed: _uploadingPhoto ? null : _takePhoto,
            icon: const Icon(Icons.photo_camera),
            label: Text(_photoFile == null ? 'Tomar foto' : 'Volver a tomar'),
          ),
        ],
      ),
    );
  }

  Widget _unitsCard(BuildContext context) {
    final unitsAsync = ref.watch(shipmentUnitsProvider(_shipment.id));
    return SectionCard(
      title: '3 · Entregar bultos',
      child: AsyncValueView<List<UnitTracking>>(
        value: unitsAsync,
        onRetry: () => ref.invalidate(shipmentUnitsProvider(_shipment.id)),
        data: (units) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_hasConfirmation)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Primero captura la confirmación del cliente.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              Text(
                'Entregados ${_delivered.length} de ${units.length} bulto(s).',
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
                        ),
                      ),
                      if (_delivered.contains(unit.unitId))
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: !_hasConfirmation || _busy
                      ? null
                      : _scanAndDeliver,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear y entregar bulto'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _scanConfirmation() async {
    final qr = await scanCode(
      context,
      title: 'QR del cliente',
      helper: 'Apunta al código del cliente que retira.',
    );
    if (qr == null || !mounted) return;
    setState(() => _confirmationController.text = qr);
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;
    // La foto se encola y se sube idempotentemente (offline-first); el backend
    // la liga al envío. No se bloquea la entrega esperando a la red.
    await ref
        .read(enqueueDeliveryPhotoProvider)
        .call(shipmentId: _shipment.id, filePath: picked.path, kind: 'pod');
    if (!mounted) return;
    setState(() {
      _photoFile = File(picked.path);
      _photoPath = 'pendiente';
      _uploadingPhoto = false;
    });
  }

  Future<void> _scanAndDeliver() async {
    final qr = await scanCode(
      context,
      title: 'Escanear bulto',
      helper: 'Apunta al QR de la etiqueta del bulto.',
      formats: const [BarcodeFormat.qrCode],
    );
    if (qr == null || !mounted) return;

    final scan = await resolveUnitScan(ref, qr);
    if (!mounted) return;
    if (scan.verified == false) {
      // Validación de etiqueta en el cliente: la mostramos en rojo con el helper
      // compartido (envuelta como ApiException para reutilizar `showErrorSnack`).
      // Distingue firma inválida de clave desconocida (igual que transportista).
      showErrorSnack(
        context,
        ApiException(
          status: 400,
          title: 'Etiqueta inválida',
          detail: unitScanErrorMessage(scan),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final outcome = await ref
          .read(recordPodProvider)
          .call(
            shipmentId: _shipment.id,
            unitId: scan.unitId,
            confirmation: _confirmationController.text.trim(),
            customerName: _shipment.customerName,
            photoPath: _photoPath,
          );
      setState(() => _delivered.add(scan.unitId));
      if (!mounted) return;
      showSubmitOutcome(context, outcome);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
