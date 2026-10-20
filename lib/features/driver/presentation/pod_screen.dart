import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/export.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/section_card.dart';
import '../data/datasources/signature_file_store.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import 'driver_common.dart';
import 'signature_pad_screen.dart';

/// Marcador de `confirmation` cuando el cliente firma en pantalla (la imagen
/// de la firma viaja aparte como evidencia por la cola de fotos).
const String kDigitalSignatureConfirmation = 'FIRMA_DIGITAL';

/// `kind` con que se sube la firma a `/app/deliveries/photos`. El contrato hoy
/// solo acepta `pod` y `damage`; se usa `pod` (lo más cercano) hasta que el
/// backend agregue `signature` (docs/backend-requests/2026-10-16-firma-cliente.md).
const String kSignatureEvidenceKind = 'pod';

/// Prueba de entrega (POD): bulto + confirmación del cliente (QR o firma en
/// pantalla) + foto obligatoria + GPS. El registro es offline-first; la foto y
/// la firma se suben aparte, por la cola de fotos.
class PodScreen extends ConsumerStatefulWidget {
  const PodScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  ConsumerState<PodScreen> createState() => _PodScreenState();
}

class _PodScreenState extends ConsumerState<PodScreen> {
  String? _unitId;
  String? _confirmation;
  XFile? _photo;

  /// PNG de la firma del cliente (solo si confirmó firmando en pantalla).
  Uint8List? _signature;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    // La foto de la entrega es obligatoria (evidencia ante reclamos).
    final ready = _unitId != null && _confirmation != null && _photo != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de entrega')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '1. Bulto entregado',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_unitId != null)
                    Text('Bulto: $_unitId')
                  else
                    const Text('Escanea el bulto a entregar.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _scanUnit,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(
                      _unitId == null ? 'Escanear bulto' : 'Reescanear',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '2. Confirmación del cliente',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_signature != null) ...[
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
                      child: Image.memory(
                        _signature!,
                        key: const ValueKey('signature-preview'),
                        fit: BoxFit.contain,
                        semanticLabel: 'Firma del cliente',
                      ),
                    ),
                  ] else if (_confirmation != null)
                    Text('Confirmación: $_confirmation')
                  else
                    const Text('Escanea el QR del cliente o pedile que firme.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _scanConfirmation,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Escanear QR del cliente'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _sign,
                    icon: const Icon(Icons.draw),
                    label: Text(
                      _signature == null
                          ? 'Firma del cliente'
                          : 'Volver a firmar',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '3. Foto de entrega (obligatoria)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      // cacheWidth: se decodifica a lo que se muestra, no a la
                      // resolución de la cámara (ahorra memoria).
                      child: Image.file(
                        File(_photo!.path),
                        height: 180,
                        fit: BoxFit.cover,
                        cacheWidth: _previewCacheWidth,
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      _photo == null ? 'Tomar foto' : 'Volver a tomar',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: ready && !_busy ? _register : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Registrar entrega'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanUnit() async {
    final unitId = await scanVerifiedUnit(context, ref);
    if (unitId != null && mounted) setState(() => _unitId = unitId);
  }

  Future<void> _scanConfirmation() async {
    final code = await scanCode(
      context,
      title: 'QR del cliente',
      helper: 'Apunta al QR de confirmación del cliente',
      formats: const [BarcodeFormat.qrCode],
    );
    if (code != null && mounted) {
      setState(() {
        _confirmation = code;
        _signature = null; // el QR reemplaza a una firma previa
      });
    }
  }

  Future<void> _sign() async {
    final png = await captureCustomerSignature(context);
    if (png != null && mounted) {
      setState(() {
        _signature = png;
        _confirmation = kDigitalSignatureConfirmation;
      });
    }
  }

  Future<void> _takePhoto() async {
    // Foto reducida (ancho y calidad acotados): en teléfonos de 1 GB una foto
    // de 12 MP a resolución completa ocupa ~48 MB al decodificarse.
    final photo = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      final fix = await currentFix(ref);
      // La foto (y la firma, si la hay) se encolan aparte y se suben
      // idempotentemente (offline-first); el backend las liga al envío. El POD
      // no espera a la subida.
      final enqueue = ref.read(enqueueDeliveryPhotoProvider);
      final photo = _photo;
      if (photo != null) {
        await enqueue(
          shipmentId: widget.stop.shipmentId,
          filePath: photo.path,
          kind: 'pod',
        );
      }
      final signature = _signature;
      if (signature != null) {
        final store = ref.read(signatureFileStoreProvider);
        try {
          final path = await store.save(signature);
          await enqueue(
            shipmentId: widget.stop.shipmentId,
            filePath: path,
            kind: kSignatureEvidenceKind,
          );
          // La cola ya copió el archivo a su directorio persistente.
          await store.discard(path);
        } on FileSystemException {
          // Sin disco para la imagen no se frena la entrega: el POD viaja
          // igual con el marcador FIRMA_DIGITAL.
        }
      }
      if (!mounted) return;
      final now = DateTime.now();
      final outcome = await ref
          .read(offlineQueueProvider)
          .submit(
            kind: 'recordProofOfDelivery',
            payload: ProofOfDeliveryRequest(
              shipmentId: widget.stop.shipmentId,
              unitId: _unitId!,
              lat: fix?.lat ?? 0,
              lng: fix?.lng ?? 0,
              occurredAt: now,
              confirmation: _confirmation!,
              photoPath: photo != null ? 'pendiente' : null,
            ).toJson(),
            label:
                'POD · ${widget.stop.customerName ?? widget.stop.shipmentId}',
            occurredAt: now,
          );
      if (!mounted) return;
      showSubmitOutcome(context, outcome);
      if (outcome != SubmitOutcome.failed) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Ancho de decodificación de la vista previa de la foto (px). La vista previa
/// mide 180 dp de alto; 800 px alcanza con nitidez sin cargar la foto entera.
const int _previewCacheWidth = 800;
