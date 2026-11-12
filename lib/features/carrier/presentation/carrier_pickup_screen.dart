import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/scan_request.dart';
import '../../../core/icons/icons.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/offline/submit_outcome.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models/carrier_scan_kind.dart';
import '../domain/usecases/record_load_scan.dart';
import 'controllers/carrier_scan_session.dart';
import 'widgets/carrier_scan_record.dart';
import 'widgets/carrier_scan_session_view.dart';
import 'widgets/carrier_scan_support.dart';

/// Escaneo del transportista al RECOGER la carga: registra cada producto como
/// escaneo de carga (offline-first). Un escaneo nunca espera a la red.
class CarrierPickupScreen extends ConsumerStatefulWidget {
  const CarrierPickupScreen({super.key});

  @override
  ConsumerState<CarrierPickupScreen> createState() =>
      _CarrierPickupScreenState();
}

class _CarrierPickupScreenState extends ConsumerState<CarrierPickupScreen> {
  static const CarrierScanKind _kind = CarrierScanKind.pickup;

  bool _busy = false;

  /// Productos con el registro EN VUELO (entre la lectura y la respuesta de la
  /// cola): dos lecturas seguidas del mismo no encolan dos registros. Lo ya
  /// recogido vive en [carrierScanSessionProvider] (sobrevive a salir y volver).
  final Set<String> _inFlight = <String>{};

  CarrierScanSession get _session =>
      ref.read(carrierScanSessionProvider(_kind).notifier);

  @override
  void initState() {
    super.initState();
    // Al abrir se rearma la tanda con lo que quedó en la cola offline: salir y
    // volver no borra el historial ni el "ya recogido".
    unawaited(_session.restoreFromQueue());
  }

  /// Escaneo CONTINUO: la cámara queda abierta y cada producto se registra al
  /// leerlo, con aviso verde/rojo sobre la cámara.
  Future<void> _scan() async {
    if (_busy) return;
    setState(() => _busy = true);
    // El GPS se calienta junto con la cámara: el registro no lo espera aparte.
    warmUpCarrierLocation(ref);
    var count = 0;
    try {
      await scanContinuous(
        context,
        title: 'Recoger carga',
        helper: 'Apunta al QR de la etiqueta de cada producto',
        formats: kLabelScanFormats,
        onCode: (qr) async {
          final feedback = await _pickupCode(qr);
          if (feedback.ok) count++;
          return feedback;
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || count == 0) return;
    showCarrierBatchSummary(
      context,
      count == 1 ? '1 producto recogido.' : '$count productos recogidos.',
    );
  }

  Future<ScanFeedback> _pickupCode(String qr) async {
    final check = await verifyLabelQr(ref, qr);
    final label = check.label;
    if (label == null) {
      return ScanFeedback.error(check.error ?? 'Etiqueta inválida');
    }
    final session = _session;
    if (_inFlight.contains(label.unitId) ||
        session.isRegistered(label.unitId)) {
      return const ScanFeedback.error('Ya recogido');
    }
    _inFlight.add(label.unitId);

    final gps = await prefetchCarrierFix(ref);
    final now = DateTime.now();
    final outcome = await ref.read(recordLoadScanProvider)(
      request: ScanRequest(
        shipmentId: label.shipmentId,
        unitId: label.unitId,
        lat: gps?.lat ?? 0,
        lng: gps?.lng ?? 0,
        occurredAt: now,
      ),
      // El prefijo identifica la fila como nuestra al rearmar la tanda.
      label: _kind.labelFor(label.sku),
    );
    _inFlight.remove(label.unitId);
    // Acotada a kMaxSessionRecords: el escaneo ya quedó en la cola.
    session.add(
      CarrierScanRecord(
        unitId: label.unitId,
        title: label.sku,
        outcome: outcome,
        at: now,
      ),
    );
    if (outcome == SubmitOutcome.failed) {
      return ScanFeedback.error(submitOutcomeMessage(outcome));
    }
    return ScanFeedback.ok('Producto recogido · ${label.sku}');
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(carrierScanSessionProvider(_kind));
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear al recoger')),
      body: CarrierScanSessionView(
        records: records,
        emptyIcon: AppIcon.pickupScan,
        emptyTitle: 'Sin productos recogidos',
        emptyMessage: 'Escanea la etiqueta de cada producto al cargarlo.',
        rowIcon: AppIcon.receive,
        actionLabel: 'Escanear producto',
        busy: _busy,
        onAction: _scan,
        actionStyle: _actionStyle,
      ),
    );
  }

  static final ButtonStyle _actionStyle = FilledButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.accentInk,
  );
}
