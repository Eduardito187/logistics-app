import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import '../domain/usecases/record_pod.dart';
import 'controllers/store_controllers.dart';
import 'unit_scan.dart';
import 'widgets/bottom_action_bar.dart';
import 'widgets/pickup_pod_cards.dart';

export 'widgets/pickup_pod_cards.dart' show kPhotoPreviewCacheWidth;

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

  /// Marca de foto adjunta para el POD: la foto viaja aparte por la cola de
  /// fotos; acá solo se indica que existe (igual que en el POD del chofer).
  String? _photoPath;
  bool _busy = false;

  /// Si hay confirmación escrita. Se cachea para reconstruir solo cuando
  /// cambia (no en cada tecla, que redibujaría la foto y la lista de bultos).
  bool _hasConfirmation = false;
  final Set<String> _delivered = <String>{};

  Shipment get _shipment => widget.shipment;

  @override
  void dispose() {
    _confirmationController.dispose();
    _evictPreview(_photoFile);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo importa si los bultos ya cargaron, no su contenido.
    final unitsLoaded = ref.watch(
      shipmentUnitsProvider(_shipment.id).select((a) => a.hasValue),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Recojo en tienda')),
      body: ResponsiveBody(
        child: Column(
          children: [
            // Slivers: la lista de productos (paso 3) es perezosa; con 100+
            // productos con foto solo se arman las filas visibles.
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverList.list(
                          children: [
                            PickupCustomerCard(shipment: _shipment),
                            const SizedBox(height: 16),
                            PickupConfirmationCard(
                              controller: _confirmationController,
                              onChanged: _onConfirmationChanged,
                              onScan: _scanConfirmation,
                            ),
                            const SizedBox(height: 16),
                            PickupPhotoCard(
                              photo: _photoFile,
                              busy: _busy,
                              onTakePhoto: _takePhoto,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        PickupUnitsCard(
                          shipmentId: _shipment.id,
                          hasConfirmation: _hasConfirmation,
                          delivered: _delivered,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Escaneo seguido de bultos: botón fijo al pie, a mano del pulgar;
            // los avisos flotan encima (kBottomActionClearance).
            BottomActionBar(
              child: FilledButton.icon(
                onPressed: !_hasConfirmation || _busy || !unitsLoaded
                    ? null
                    : _scanAndDeliver,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear y entregar producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirmationChanged(String _) {
    final has = _confirmationController.text.trim().isNotEmpty;
    if (has != _hasConfirmation) setState(() => _hasConfirmation = has);
  }

  Future<void> _scanConfirmation() async {
    final qr = await scanCode(
      context,
      title: 'QR del cliente',
      helper: 'Apunta al código del cliente que retira.',
    );
    if (qr == null || !mounted) return;
    _confirmationController.text = qr;
    _onConfirmationChanged(qr);
  }

  Future<void> _takePhoto() async {
    final picked = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (picked == null || !mounted) return;
    // La foto se encola y se sube idempotentemente (offline-first); el backend
    // la liga al envío. No se bloquea la entrega esperando a la red.
    try {
      await ref
          .read(enqueueDeliveryPhotoProvider)
          .call(shipmentId: _shipment.id, filePath: picked.path, kind: 'pod');
    } catch (_) {
      // Falla local (copiar a disco), no de red: hay que volver a tomarla.
      if (!mounted) return;
      showErrorSnack(
        context,
        'No se pudo guardar la foto. Intentá de nuevo.',
        bottomClearance: kBottomActionClearance,
      );
      return;
    }
    if (!mounted) return;
    // La vista previa anterior ya no se muestra: se libera de la caché.
    _evictPreview(_photoFile);
    setState(() {
      _photoFile = File(picked.path);
      _photoPath = 'pendiente';
    });
  }

  /// Saca de la caché de imágenes la vista previa decodificada de [file].
  void _evictPreview(File? file) {
    if (file == null) return;
    unawaited(
      ResizeImage(FileImage(file), width: kPhotoPreviewCacheWidth).evict(),
    );
  }

  /// Escaneo CONTINUO (tras la confirmación del cliente): la cámara queda
  /// abierta y cada producto se entrega al leerlo, con aviso sobre la cámara.
  Future<void> _scanAndDeliver() async {
    // El GPS se calienta junto con la cámara: el POD no lo espera aparte.
    warmUpLocation(ref);
    final before = _delivered.length;
    setState(() => _busy = true);
    try {
      await scanContinuous(
        context,
        title: 'Escanear producto',
        helper: 'Apunta al QR de la etiqueta del producto.',
        formats: const [BarcodeFormat.qrCode],
        onCode: _deliverCode,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final delivered = _delivered.length - before;
    if (delivered <= 0) return;
    showSuccessSnack(
      context,
      delivered == 1
          ? '1 producto entregado.'
          : '$delivered productos entregados.',
      bottomClearance: kBottomActionClearance,
    );
  }

  /// Procesa un código de la ráfaga de entrega.
  Future<ScanFeedback> _deliverCode(String qr) async {
    final scan = await resolveUnitScan(ref, qr);
    if (!mounted) return const ScanFeedback.error('Pantalla cerrada');
    // Validación de etiqueta en el cliente (offline): firma inválida o clave
    // desconocida, igual que transportista.
    if (scan.verified == false) {
      return ScanFeedback.error(unitScanShortError(scan));
    }

    // Solo bultos de este envío y una sola vez: si no, se entregaría al cliente
    // algo ajeno o se encolaría un POD duplicado.
    final units = ref.read(shipmentUnitsProvider(_shipment.id)).value;
    final unitId = scan.unitId;
    if (units != null && !units.any((u) => u.unitId == unitId)) {
      return const ScanFeedback.error('No es de este pedido');
    }
    if (_delivered.contains(unitId)) {
      return const ScanFeedback.error('Ya entregado');
    }

    // Feedback inmediato: el bulto se marca entregado apenas se lee; el POD
    // se guarda local y sube por la cola.
    setState(() => _delivered.add(unitId));
    final outcome = await ref
        .read(recordPodProvider)
        .call(
          shipmentId: _shipment.id,
          unitId: unitId,
          confirmation: _confirmationController.text.trim(),
          customerName: _shipment.customerName,
          photoPath: _photoPath,
          location: prefetchFix(ref),
        );
    if (outcome == SubmitOutcome.failed) {
      // Rechazado por el backend: no queda como entregado.
      if (mounted) setState(() => _delivered.remove(unitId));
      return ScanFeedback.error(submitOutcomeMessage(outcome));
    }
    final total = units?.length;
    return ScanFeedback.ok(
      total == null
          ? 'Producto entregado'
          : 'Producto entregado (${_delivered.length}/$total)',
    );
  }
}
