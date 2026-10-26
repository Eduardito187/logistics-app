import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/proof_of_delivery_request.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/offline/submit_outcome.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../domain/usecases/record_proof_of_delivery.dart';
import 'widgets/carrier_scan_record.dart';
import 'widgets/carrier_scan_session_view.dart';
import 'widgets/carrier_scan_support.dart';
import 'widgets/signed_label_result.dart';

/// Escaneo del transportista al ENTREGAR: prueba de entrega. Escanea el bulto,
/// luego el QR de confirmación del cliente, y registra la entrega offline-first.
class CarrierDeliverScreen extends ConsumerStatefulWidget {
  const CarrierDeliverScreen({super.key});

  @override
  ConsumerState<CarrierDeliverScreen> createState() =>
      _CarrierDeliverScreenState();
}

class _CarrierDeliverScreenState extends ConsumerState<CarrierDeliverScreen> {
  final List<CarrierScanRecord> _records = [];
  bool _busy = false;

  /// Bultos ya entregados (no rechazados) en esta pantalla: un segundo
  /// escaneo del mismo no encola otra prueba de entrega.
  final Set<String> _delivered = <String>{};

  /// Primero el QR de confirmación del cliente (una vez por entrega) y después
  /// escaneo CONTINUO de sus bultos: la cámara queda abierta y cada bulto se
  /// registra al leerlo. Todos los bultos de la tanda deben ser del mismo
  /// pedido (la confirmación es de ese cliente).
  Future<void> _deliver() async {
    if (_busy) return;
    setState(() => _busy = true);
    // El GPS se calienta junto con la cámara: el registro no lo espera aparte.
    warmUpCarrierLocation(ref);
    var count = 0;
    try {
      final confirmation = await scanCode(
        context,
        title: 'Confirmación del cliente',
        helper: 'Escanea el QR del cliente para confirmar la entrega',
        formats: const [BarcodeFormat.qrCode],
      );
      if (confirmation == null || !mounted) return;

      String? shipmentId;
      await scanContinuous(
        context,
        title: 'Entregar bultos',
        helper: 'Apunta al QR de la etiqueta de cada bulto',
        formats: const [BarcodeFormat.qrCode],
        onCode: (qr) async {
          final check = await verifyLabelQr(ref, qr);
          final label = check.label;
          if (label == null) {
            return ScanFeedback.error(check.error ?? 'Etiqueta inválida');
          }
          if (shipmentId != null && label.shipmentId != shipmentId) {
            return const ScanFeedback.error('No es de este pedido');
          }
          final feedback = await _deliverUnit(label, confirmation);
          if (feedback.ok) {
            shipmentId ??= label.shipmentId;
            count++;
          }
          return feedback;
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || count == 0) return;
    showCarrierBatchSummary(
      context,
      count == 1 ? '1 bulto entregado.' : '$count bultos entregados.',
    );
  }

  Future<ScanFeedback> _deliverUnit(
    SignedLabelResult label,
    String confirmation,
  ) async {
    if (_delivered.contains(label.unitId)) {
      return const ScanFeedback.error('Ya entregado');
    }
    _delivered.add(label.unitId);
    final gps = await prefetchCarrierFix(ref);
    final now = DateTime.now();
    final outcome = await ref.read(recordProofOfDeliveryProvider)(
      request: ProofOfDeliveryRequest(
        shipmentId: label.shipmentId,
        unitId: label.unitId,
        lat: gps?.lat ?? 0,
        lng: gps?.lng ?? 0,
        occurredAt: now,
        confirmation: confirmation,
      ),
      label: 'Entrega · ${label.sku}',
    );
    if (outcome == SubmitOutcome.failed) _delivered.remove(label.unitId);
    if (mounted) {
      setState(() {
        // Acotada a kMaxSessionRecords: la entrega ya quedó en la cola.
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
    return ScanFeedback.ok('Bulto entregado · ${label.sku}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear al entregar')),
      body: CarrierScanSessionView(
        records: _records,
        emptyIcon: Icons.task_alt,
        emptyTitle: 'Sin entregas registradas',
        emptyMessage:
            'Escanea el bulto y el QR del cliente para registrar la entrega.',
        rowIcon: Icons.check_circle_outline,
        actionLabel: 'Registrar entrega',
        busy: _busy,
        onAction: _deliver,
      ),
    );
  }
}
