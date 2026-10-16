import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/export.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/photo_upload_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/section_card.dart';
import 'driver_common.dart';

/// Prueba de entrega (POD): bulto + confirmación del cliente + foto + GPS.
/// El registro es offline-first; la foto se sube cuando hay red.
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
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ready = _unitId != null && _confirmation != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de entrega')),
      body: ListView(
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
                if (_confirmation != null)
                  Text('Confirmación: $_confirmation')
                else
                  const Text('Escanea el QR del cliente o registra firma.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _scanConfirmation,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Escanear QR del cliente'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _confirmation = 'FIRMA_PAPEL'),
                  icon: const Icon(Icons.draw),
                  label: const Text('Firma en papel (sin QR)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '3. Foto de entrega',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photo!.path),
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_photo == null ? 'Tomar foto' : 'Volver a tomar'),
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
    if (code != null && mounted) setState(() => _confirmation = code);
  }

  Future<void> _takePhoto() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      final fix = await currentFix(ref);
      // La foto se encola aparte y se sube idempotentemente (offline-first); el
      // backend la liga al envío. El POD no espera a la subida.
      final photo = _photo;
      if (photo != null) {
        await ref
            .read(photoUploadQueueProvider)
            .enqueue(
              shipmentId: widget.stop.shipmentId,
              filePath: photo.path,
              kind: 'pod',
            );
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
