import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/scan_request.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/offline/submit_outcome.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/usecases/record_load_scan.dart';
import 'widgets/carrier_scan_record.dart';
import 'widgets/carrier_scan_session_view.dart';
import 'widgets/carrier_scan_support.dart';

/// Escaneo del transportista al RECOGER la carga: registra cada bulto como
/// escaneo de carga (offline-first). Un escaneo nunca espera a la red.
class CarrierPickupScreen extends ConsumerStatefulWidget {
  const CarrierPickupScreen({super.key});

  @override
  ConsumerState<CarrierPickupScreen> createState() =>
      _CarrierPickupScreenState();
}

class _CarrierPickupScreenState extends ConsumerState<CarrierPickupScreen> {
  final List<CarrierScanRecord> _records = [];
  bool _busy = false;

  /// Bultos ya recogidos (no rechazados) en esta pantalla: un segundo escaneo
  /// del mismo no encola otro registro.
  final Set<String> _picked = <String>{};

  /// Escaneo CONTINUO: la cámara queda abierta y cada bulto se registra al
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
        helper: 'Apunta al QR de la etiqueta de cada bulto',
        formats: const [BarcodeFormat.qrCode],
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
      count == 1 ? '1 bulto recogido.' : '$count bultos recogidos.',
    );
  }

  Future<ScanFeedback> _pickupCode(String qr) async {
    final check = await verifyLabelQr(ref, qr);
    final label = check.label;
    if (label == null) {
      return ScanFeedback.error(check.error ?? 'Etiqueta inválida');
    }
    if (_picked.contains(label.unitId)) {
      return const ScanFeedback.error('Ya recogido');
    }
    _picked.add(label.unitId);

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
      label: 'Recojo · ${label.sku}',
    );
    if (outcome == SubmitOutcome.failed) _picked.remove(label.unitId);
    if (mounted) {
      setState(() {
        // Acotada a kMaxSessionRecords: el escaneo ya quedó en la cola.
        addSessionRecord(
          _records,
          CarrierScanRecord(
            unitId: label.unitId,
            title: label.sku,
            outcome: outcome,
            at: now,
          ),
        );
      });
    }
    if (outcome == SubmitOutcome.failed) {
      return ScanFeedback.error(submitOutcomeMessage(outcome));
    }
    return ScanFeedback.ok('Bulto recogido · ${label.sku}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear al recoger')),
      body: CarrierScanSessionView(
        records: _records,
        emptyIcon: Icons.upload_file,
        emptyTitle: 'Sin bultos recogidos',
        emptyMessage: 'Escanea la etiqueta de cada bulto al cargarlo.',
        rowIcon: Icons.inventory_2_outlined,
        actionLabel: 'Escanear bulto',
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
