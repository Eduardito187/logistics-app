import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/labels/label_format_exception.dart';
import '../../../core/labels/signed_label.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/store_stop.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_common.dart';
import 'widgets/evidence_photo_preview.dart';

/// El camión DEJA el pedido en la tienda (decisión del dueño, nov 2026).
///
/// No es una entrega al cliente: el chofer **escanea los productos** y saca
/// **una foto** — sin firma ni documento. Al registrar, el backend marca el
/// pedido "en tienda, listo para retirar" (NO entregado) y le avisa al cliente.
/// Que el cliente lo retire es otro flujo, posterior, del personal de tienda.
///
/// Offline-first: los escaneos de descarga, la foto y el cierre
/// (`store-drop`) se encolan; la parada queda resuelta en el teléfono al
/// instante.
class StoreDropScreen extends ConsumerStatefulWidget {
  const StoreDropScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  ConsumerState<StoreDropScreen> createState() => _StoreDropScreenState();
}

class _StoreDropScreenState extends ConsumerState<StoreDropScreen> {
  /// Productos escaneados, en orden y sin repetir.
  final List<String> _unitIds = <String>[];

  /// Cantidad de productos del pedido, o `null` si no se sabe (no se exige
  /// total: alcanza con uno).
  int? _expectedCount;
  XFile? _photo;
  bool _busy = false;

  DriverRouteStop get _stop => widget.stop;

  @override
  void initState() {
    super.initState();
    // GPS caliente al entrar: al registrar, el fix ya está y no se espera.
    ref.read(locationServiceProvider).prefetch();
    // Mismo criterio del POD: `unit_ids` manda, acotado por la suma de
    // cantidades de los ítems (una etiqueta duplicada no suma de más).
    final unitIds = _stop.unitIds;
    final fromItems = _stop.items.fold<int>(0, (sum, i) => sum + i.quantity);
    if (unitIds != null && unitIds.isNotEmpty) {
      _expectedCount = fromItems > 0
          ? math.min(unitIds.length, fromItems)
          : unitIds.length;
    } else if (fromItems > 0) {
      _expectedCount = fromItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _expectedCount;
    final complete =
        _unitIds.isNotEmpty && (total == null || _unitIds.length >= total);
    final reachedTotal = total != null && _unitIds.length >= total;
    final ready = complete && _photo != null;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Entregar en tienda')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              storeStopName(_stop),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_stop.orderReference != null)
              Text('Pedido ${_stop.orderReference}'),
            const SizedBox(height: 4),
            Text(
              'Dejás el pedido en la tienda: escaneá los productos y sacá una '
              'foto. No hace falta firma.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '1. Productos que dejás',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_summary()),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy || reachedTotal ? null : _scan,
                    icon: const AnimatedAppIcon(AppIcon.scan),
                    label: Text(
                      _unitIds.isEmpty
                          ? 'Escanear producto'
                          : 'Escanear siguiente',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '2. Foto de entrega (obligatoria)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_photo != null) ...[
                    EvidencePhotoPreview(path: _photo!.path),
                    const SizedBox(height: 12),
                  ],
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
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: ready && !_busy ? _register : null,
                icon: AnimatedAppIcon(
                  AppIcon.success,
                  state: _busy ? AppIconState.loading : AppIconState.idle,
                ),
                label: const Text('Registrar entrega en tienda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summary() {
    final total = _expectedCount;
    if (_unitIds.isEmpty) {
      return total == null
          ? 'Escaneá cada producto que dejás.'
          : 'Escaneá los $total productos del pedido.';
    }
    return total == null
        ? 'Escaneados: ${_unitIds.length}'
        : 'Escaneados ${_unitIds.length} de $total';
  }

  Future<void> _scan() async {
    final qr = await scanCode(
      context,
      title: 'Escanear producto',
      helper: 'Apunta al QR del producto',
      formats: kLabelScanFormats,
    );
    if (qr == null || !mounted) return;
    // La etiqueta debe ser de ESTE pedido (por nº de orden del QR). Si no se
    // puede saber (Code128), no bloquea: offline-first.
    if (!_belongsByOrder(qr)) {
      showInfoSnack(context, 'Ese producto es de otro pedido.');
      return;
    }
    final unitId = await verifyUnitLabel(ref, qr);
    if (!mounted) return;
    if (unitId == null) {
      showInfoSnack(context, 'Etiqueta no válida');
      return;
    }
    if (_unitIds.contains(unitId)) {
      showInfoSnack(context, 'Ese producto ya lo escaneaste.');
      return;
    }
    setState(() => _unitIds.add(unitId));
  }

  bool _belongsByOrder(String qr) {
    final order = _stop.orderReference;
    if (order == null) return true;
    try {
      return SignedLabel.fromQrContent(qr).payload.orderNumber == order;
    } on LabelFormatException {
      return true;
    }
  }

  Future<void> _takePhoto() async {
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
      if (!mounted) return;
      final shipmentId = _stop.shipmentId;
      final nodeId = _stop.destinationNodeId;
      final now = DateTime.now();
      final lat = fix?.lat ?? 0;
      final lng = fix?.lng ?? 0;
      final tienda = storeStopName(_stop);
      // La foto viaja por su cola (el backend la liga al envío al llegar).
      final photo = _photo;
      if (photo != null) {
        await ref.read(enqueueDeliveryPhotoProvider)(
          shipmentId: shipmentId,
          filePath: photo.path,
          kind: 'pod',
        );
      }
      if (!mounted) return;
      final queue = ref.read(offlineQueueProvider);
      // Constancia por producto (descarga). No cierra la parada: la cierra el
      // `store-drop` de abajo. Su rechazo no frena la entrega.
      for (final unitId in _unitIds) {
        await queue.submit(
          kind: 'recordUnloadScan',
          payload: UnloadScanRequest(
            shipmentId: shipmentId,
            unitId: unitId,
            lat: lat,
            lng: lng,
            occurredAt: now,
            nodeId: nodeId ?? _stop.id,
          ).toJson(),
          label: 'Descarga en tienda · $unitId',
          occurredAt: now,
        );
      }
      String? rejectDetail;
      final outcome = await queue.submit(
        onReject: (error) => rejectDetail ??= error.message,
        kind: 'recordStoreDrop',
        payload: <String, Object?>{
          '@shipmentId': shipmentId,
          'node_id': ?nodeId,
          'occurred_at': now.toUtc().toIso8601String(),
          if (fix != null) 'lat': fix.lat,
          if (fix != null) 'lng': fix.lng,
        },
        label: 'Entrega en tienda · $tienda',
        occurredAt: now,
      );
      if (!mounted) return;
      showSubmitOutcome(context, outcome, failureDetail: rejectDetail);
      if (outcome != SubmitOutcome.failed) {
        // Encolado o enviado: la parada queda resuelta en la UI ya mismo.
        ref
            .read(locallySettledStopsProvider.notifier)
            .settle(_stop.id, DriverRouteStopStatus.completed);
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
