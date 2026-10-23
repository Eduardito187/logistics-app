import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/export.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/photo_upload_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import 'driver_common.dart';

/// Entrega fallida: bulto + motivo tipado + foto opcional + GPS, registro
/// offline-first.
class FailedDeliveryScreen extends ConsumerStatefulWidget {
  const FailedDeliveryScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  ConsumerState<FailedDeliveryScreen> createState() =>
      _FailedDeliveryScreenState();
}

class _FailedDeliveryScreenState extends ConsumerState<FailedDeliveryScreen> {
  String? _unitId;
  FailureReason _reason = FailureReason.customerAbsent;
  XFile? _photo;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ready = _unitId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Entrega fallida')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '1. Bulto',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _unitId == null ? 'Escanea el bulto.' : 'Bulto: $_unitId',
                  ),
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
              title: '2. Motivo',
              // Flutter 3.32: sin RadioGroup, cada tile lleva groupValue/onChanged.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final reason in FailureReason.$valuesDefined)
                    RadioListTile<FailureReason>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_reasonLabel(reason)),
                      value: reason,
                      groupValue: _reason,
                      onChanged: (value) {
                        if (_busy || value == null) return;
                        setState(() => _reason = value);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '3. Foto (opcional)',
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
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              onPressed: ready && !_busy ? _register : null,
              icon: const Icon(Icons.cancel),
              label: const Text('Registrar entrega fallida'),
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
      // La foto de daños se encola aparte y se sube idempotentemente; el
      // registro de la falla no espera a la red.
      final photo = _photo;
      if (photo != null) {
        await ref
            .read(photoUploadQueueProvider)
            .enqueue(
              shipmentId: widget.stop.shipmentId,
              filePath: photo.path,
              kind: 'damage',
            );
      }
      if (!mounted) return;
      final now = DateTime.now();
      final outcome = await ref
          .read(offlineQueueProvider)
          .submit(
            kind: 'recordFailedDelivery',
            payload: FailedDeliveryRequest(
              shipmentId: widget.stop.shipmentId,
              unitId: _unitId!,
              lat: fix?.lat ?? 0,
              lng: fix?.lng ?? 0,
              occurredAt: now,
              reason: _reason,
            ).toJson(),
            label: 'Fallida · ${_reasonLabel(_reason)}',
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

String _reasonLabel(FailureReason reason) => switch (reason) {
  FailureReason.customerAbsent => 'Cliente ausente',
  FailureReason.wrongAddress => 'Dirección incorrecta',
  FailureReason.rejected => 'Pedido rechazado',
  FailureReason.damaged => 'Producto dañado',
  FailureReason.other => 'Otro motivo',
  _ => 'Motivo',
};

/// Ancho de decodificación de la vista previa de la foto (px). La vista previa
/// mide 180 dp de alto; 800 px alcanza con nitidez sin cargar la foto entera.
const int _previewCacheWidth = 800;
