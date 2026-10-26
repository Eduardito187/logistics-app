import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/export.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/photo_upload_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/widgets/section_card.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_common.dart';
import 'widgets/evidence_photo_preview.dart';

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
  void initState() {
    super.initState();
    // GPS caliente al entrar: al registrar, el fix ya está y no se espera.
    ref.read(locationServiceProvider).prefetch();
  }

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
                  // Decodificada chica y liberada del caché al salir.
                  if (_photo != null) EvidencePhotoPreview(path: _photo!.path),
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
                backgroundColor: Colors.red.shade700,
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
      // El GPS se pide en paralelo con el encolado de la foto (no en serie).
      final fixFuture = currentFix(ref);
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
      final fix = await fixFuture;
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
      if (outcome != SubmitOutcome.failed) {
        // Encolado o enviado: la parada queda resuelta en la UI ya mismo (la
        // entrega en curso pasa a la siguiente aunque no haya señal).
        ref
            .read(locallySettledStopsProvider.notifier)
            .settle(widget.stop.id, DriverRouteStopStatus.failed);
        Navigator.of(context).pop();
      }
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
