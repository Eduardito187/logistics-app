import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/export.dart';
import '../../../core/catalog/failure_reason_option.dart';
import '../../../core/catalog/failure_reasons_repository.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/photo_upload_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_common.dart';
import 'widgets/evidence_photo_preview.dart';

/// Entrega fallida: producto + motivo (configurable por el admin) + foto y/o
/// texto según exija ese motivo + GPS, registro offline-first.
///
/// Los motivos salen del catálogo (`activeFailureReasonsProvider`); si el
/// backend aún no lo tiene o no hay red, caen a los de fábrica. Por cada motivo,
/// el admin decide si la **foto** es obligatoria y si hay que escribir un
/// **texto/observación**.
class FailedDeliveryScreen extends ConsumerStatefulWidget {
  const FailedDeliveryScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  ConsumerState<FailedDeliveryScreen> createState() =>
      _FailedDeliveryScreenState();
}

class _FailedDeliveryScreenState extends ConsumerState<FailedDeliveryScreen> {
  String? _unitId;
  String? _selectedCode;
  final TextEditingController _note = TextEditingController();
  XFile? _photo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // GPS caliente al entrar: al registrar, el fix ya está y no se espera.
    ref.read(locationServiceProvider).prefetch();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Opciones visibles; mientras carga (o si falla) usa las de fábrica para que
  /// la pantalla nunca quede sin motivos.
  List<FailureReasonOption> _options() {
    final async = ref.watch(activeFailureReasonsProvider);
    final list = async.value;
    if (list == null || list.isEmpty) {
      return kDefaultFailureReasons.where((r) => r.active).toList();
    }
    return list;
  }

  FailureReasonOption? _selected(List<FailureReasonOption> options) {
    if (options.isEmpty) return null;
    for (final option in options) {
      if (option.code == _selectedCode) return option;
    }
    // Sin selección aún (o el código elegido ya no existe): el primero.
    return options.first;
  }

  @override
  Widget build(BuildContext context) {
    final options = _options();
    final selected = _selected(options);
    final needsNote = selected?.requiresNote ?? false;
    final needsPhoto = selected?.requiresPhoto ?? false;
    final noteOk = !needsNote || _note.text.trim().isNotEmpty;
    final photoOk = !needsPhoto || _photo != null;
    final ready = _unitId != null && selected != null && noteOk && photoOk;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrega fallida')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '1. Producto',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _unitId == null
                        ? 'Escanea el producto.'
                        : 'Producto: $_unitId',
                  ),
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
              title: '2. Motivo',
              // Flutter 3.32: sin RadioGroup, cada tile lleva groupValue/onChanged.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final option in options)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.label),
                      value: option.code,
                      groupValue: selected?.code,
                      onChanged: (value) {
                        if (_busy || value == null) return;
                        setState(() => _selectedCode = value);
                      },
                    ),
                ],
              ),
            ),
            if (needsNote) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: selected!.noteFieldLabel,
                child: TextField(
                  controller: _note,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 280,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribí lo que pasó',
                  ),
                  // Habilita/deshabilita el botón al escribir.
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SectionCard(
              title: needsPhoto ? '3. Foto (obligatoria)' : '3. Foto (opcional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Decodificada chica y liberada del caché al salir.
                  if (_photo != null) EvidencePhotoPreview(path: _photo!.path),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: ready && !_busy ? () => _register(selected!) : null, // ignore: unnecessary_non_null_assertion
              icon: AnimatedAppIcon(
                AppIcon.cancel,
                state: _busy ? AppIconState.loading : AppIconState.idle,
              ),
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

  Future<void> _register(FailureReasonOption reason) async {
    final note = _note.text.trim();
    // Resguardo (el botón ya lo impide): no registrar sin lo que el motivo exige.
    if (reason.requiresNote && note.isEmpty) {
      showInfoSnack(context, 'Escribí ${reason.noteFieldLabel.toLowerCase()}.');
      return;
    }
    if (reason.requiresPhoto && _photo == null) {
      showInfoSnack(context, 'Este motivo necesita una foto.');
      return;
    }
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
      // Cuerpo armado a mano (no por el DTO generado): `reason` es el CÓDIGO del
      // motivo configurado (puede ser uno que creó el admin, fuera del enum) y
      // viaja también la observación. El transporte va por Dio directo en el
      // dispatcher offline (`recordFailedDelivery`).
      final outcome = await ref
          .read(offlineQueueProvider)
          .submit(
            kind: 'recordFailedDelivery',
            payload: <String, Object?>{
              'shipment_id': widget.stop.shipmentId,
              'unit_id': _unitId,
              'lat': fix?.lat ?? 0,
              'lng': fix?.lng ?? 0,
              'occurred_at': now.toUtc().toIso8601String(),
              'reason': reason.code,
              if (note.isNotEmpty) 'note': note,
              // La foto viaja aparte por su cola idempotente (kind damage); esta
              // señal le dice al backend que la evidencia ya fue tomada, para
              // que `requires_photo` se dé por cumplida sin esperar la subida
              // (offline-first). Ver backend-requests/2026-11-17-motivos-...md.
              if (photo != null) 'has_photo': true,
            },
            label: 'Fallida · ${reason.label}',
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
