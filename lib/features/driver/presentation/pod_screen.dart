import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/sharing/share_service.dart';
import '../../../core/widgets/section_card.dart';
import '../data/datasources/signature_file_store.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_common.dart';
import 'signature_pad_screen.dart';
import 'widgets/evidence_photo_preview.dart';

/// Marcador de `confirmation` cuando el cliente firma en pantalla (la imagen
/// de la firma viaja aparte como evidencia por la cola de fotos).
const String kDigitalSignatureConfirmation = 'FIRMA_DIGITAL';

/// `kind` de la firma del cliente: va al endpoint de EVIDENCIA anti-fraude
/// (`/app/deliveries/evidence`) LIGADA al cliente (snapshot) y se valida en el
/// backend (docs/backend-requests/2026-11-05-evidencia-ligada-al-cliente-antifraude.md).
const String kSignatureEvidenceKind = 'signature';

/// `kind` de la foto del documento (carnet) del cliente: evidencia anti-fraude
/// ligada al cliente; el backend hace OCR del nº y lo cruza con el documento del
/// cliente.
const String kDocumentEvidenceKind = 'id_document';

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

  /// Foto del documento (carnet) del cliente — evidencia anti-fraude OPCIONAL.
  XFile? _document;

  /// PNG de la firma del cliente (solo si confirmó firmando en pantalla).
  Uint8List? _signature;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // GPS caliente al entrar: al registrar, el fix ya está y no se espera.
    ref.read(locationServiceProvider).prefetch();
  }

  @override
  Widget build(BuildContext context) {
    // La foto de la entrega es obligatoria (evidencia ante reclamos).
    final ready = _unitId != null && _confirmation != null && _photo != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante de entrega')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '1. Producto entregado',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_unitId != null)
                    Text('Producto: $_unitId')
                  else
                    const Text('Escanea el producto a entregar.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _scanUnit,
                    icon: const AnimatedAppIcon(AppIcon.scan),
                    label: Text(
                      _unitId == null ? 'Escanear producto' : 'Reescanear',
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
                      child: SignaturePreview(
                        key: const ValueKey('signature-preview'),
                        png: _signature!,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _shareSignature,
                        icon: const AnimatedAppIcon(AppIcon.send, size: 18),
                        label: const Text('Compartir firma'),
                      ),
                    ),
                  ] else if (_confirmation != null)
                    Text('Confirmación: $_confirmation')
                  else
                    const Text('Escanea el QR del cliente o pedile que firme.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _scanConfirmation,
                    icon: const AnimatedAppIcon(AppIcon.qrCode),
                    label: const Text('Escanear QR del cliente'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _sign,
                    icon: const AnimatedAppIcon(AppIcon.signature),
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
                  // Decodificada chica y liberada del caché al salir.
                  if (_photo != null) ...[
                    EvidencePhotoPreview(path: _photo!.path),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _sharePhoto,
                        icon: const AnimatedAppIcon(AppIcon.send, size: 18),
                        label: const Text('Compartir foto'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _takePhoto,
                    icon: const AnimatedAppIcon(AppIcon.capture),
                    label: Text(
                      _photo == null ? 'Tomar foto' : 'Volver a tomar',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '4. Documento del cliente (opcional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_document != null) ...[
                    EvidencePhotoPreview(path: _document!.path),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _shareDocument,
                        icon: const AnimatedAppIcon(AppIcon.send, size: 18),
                        label: const Text('Compartir documento'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _takeDocument,
                    icon: const AnimatedAppIcon(AppIcon.capture),
                    label: Text(
                      _document == null
                          ? 'Foto del documento'
                          : 'Volver a tomar',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: ready && !_busy ? _register : null,
              icon: AnimatedAppIcon(
                AppIcon.success,
                state: _busy ? AppIconState.loading : AppIconState.idle,
              ),
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

  /// Comparte la firma del cliente por el menú nativo (WhatsApp, correo, etc.).
  Future<void> _shareSignature() async {
    final sig = _signature;
    if (sig == null || _busy) return;
    final cliente = widget.stop.customerName ?? 'Entrega';
    await ref
        .read(shareServiceProvider)
        .shareImagePng(
          sig,
          filename: 'firma_${widget.stop.shipmentId}.png',
          text: 'Firma del cliente · $cliente',
        );
  }

  /// Comparte la foto de evidencia (documento/entrega) por el menú nativo.
  Future<void> _sharePhoto() async {
    final photo = _photo;
    if (photo == null || _busy) return;
    final cliente = widget.stop.customerName ?? 'Entrega';
    await ref
        .read(shareServiceProvider)
        .shareFile(photo.path, text: 'Foto de entrega · $cliente');
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

  Future<void> _takeDocument() async {
    final doc = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (doc != null && mounted) setState(() => _document = doc);
  }

  Future<void> _shareDocument() async {
    final doc = _document;
    if (doc == null || _busy) return;
    final cliente = widget.stop.customerName ?? 'Cliente';
    await ref
        .read(shareServiceProvider)
        .shareFile(doc.path, text: 'Documento del cliente · $cliente');
  }

  /// Snapshot del cliente para LIGAR la evidencia a su identidad (anti-fraude):
  /// nombre, teléfono, ubicación de captura y momento. El backend cruza el envío
  /// con el cliente; esto deja constancia de a quién dijo el chofer que entregó.
  Map<String, Object?> _clientSnapshot(GpsFix? fix) => {
    if (widget.stop.customerName != null)
      'customer_name': widget.stop.customerName,
    if (widget.stop.customerPhone != null)
      'customer_phone': widget.stop.customerPhone,
    if (fix != null) 'lat': fix.lat,
    if (fix != null) 'lng': fix.lng,
    'captured_at': DateTime.now().toUtc().toIso8601String(),
  };

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      // El GPS se pide primero: su posición va en el snapshot del cliente de la
      // evidencia anti-fraude (firma/documento) y en el POD. Suele salir de la
      // caché (se precalentó al abrir).
      final fix = await currentFix(ref);
      if (!mounted) return;
      final snapshot = _clientSnapshot(fix);
      // La foto, la firma y el documento se encolan aparte y se suben
      // idempotentemente (offline-first). El POD no espera a la subida.
      final enqueue = ref.read(enqueueDeliveryPhotoProvider);
      final photo = _photo;
      if (photo != null) {
        await enqueue(
          shipmentId: widget.stop.shipmentId,
          filePath: photo.path,
          kind: 'pod',
        );
      }
      final document = _document;
      if (document != null) {
        await enqueue(
          shipmentId: widget.stop.shipmentId,
          filePath: document.path,
          kind: kDocumentEvidenceKind,
          clientSnapshot: snapshot,
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
            clientSnapshot: snapshot,
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
            label: 'POD · ${widget.stop.customerName ?? 'Entrega'}',
            occurredAt: now,
          );
      if (!mounted) return;
      showSubmitOutcome(context, outcome);
      if (outcome != SubmitOutcome.failed) {
        // Encolado o enviado: la parada queda resuelta en la UI ya mismo (la
        // entrega en curso pasa a la siguiente aunque no haya señal).
        ref
            .read(locallySettledStopsProvider.notifier)
            .settle(widget.stop.id, DriverRouteStopStatus.completed);
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
