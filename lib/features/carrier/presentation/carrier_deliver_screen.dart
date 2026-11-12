import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/proof_of_delivery_request.dart';
import '../../../core/icons/icons.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/offline/submit_outcome.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../domain/models/carrier_scan_kind.dart';
import '../domain/usecases/record_proof_of_delivery.dart';
import 'controllers/carrier_scan_session.dart';
import 'widgets/carrier_scan_record.dart';
import 'widgets/carrier_scan_session_view.dart';
import 'widgets/carrier_scan_support.dart';
import 'widgets/signed_label_result.dart';

/// Escaneo del transportista al ENTREGAR: prueba de entrega. Escanea el
/// producto, luego el QR de confirmación del cliente, y registra la entrega
/// offline-first.
class CarrierDeliverScreen extends ConsumerStatefulWidget {
  const CarrierDeliverScreen({super.key});

  @override
  ConsumerState<CarrierDeliverScreen> createState() =>
      _CarrierDeliverScreenState();
}

class _CarrierDeliverScreenState extends ConsumerState<CarrierDeliverScreen> {
  static const CarrierScanKind _kind = CarrierScanKind.deliver;

  bool _busy = false;

  /// Productos con la entrega EN VUELO (entre la lectura y la respuesta de la
  /// cola): dos lecturas seguidas del mismo no encolan dos pruebas de entrega.
  /// Lo ya entregado vive en [carrierScanSessionProvider] (sobrevive a salir y
  /// volver a la pantalla).
  final Set<String> _inFlight = <String>{};

  CarrierScanSession get _session =>
      ref.read(carrierScanSessionProvider(_kind).notifier);

  @override
  void initState() {
    super.initState();
    // Al abrir se rearma la tanda con lo que quedó en la cola offline: salir y
    // volver no borra el historial ni el "ya entregado".
    unawaited(_session.restoreFromQueue());
  }

  /// Primero el QR de confirmación del cliente (una vez por entrega) y después
  /// escaneo CONTINUO de sus productos: la cámara queda abierta y cada producto
  /// se registra al leerlo. Todos los productos de la tanda deben ser del mismo
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
        title: 'Entregar productos',
        helper: 'Apunta al QR de la etiqueta de cada producto',
        formats: kLabelScanFormats,
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
      count == 1 ? '1 producto entregado.' : '$count productos entregados.',
    );
  }

  Future<ScanFeedback> _deliverUnit(
    SignedLabelResult label,
    String confirmation,
  ) async {
    final session = _session;
    if (_inFlight.contains(label.unitId) ||
        session.isRegistered(label.unitId)) {
      return const ScanFeedback.error('Ya entregado');
    }
    _inFlight.add(label.unitId);
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
      // El prefijo identifica la fila como nuestra al rearmar la tanda.
      label: _kind.labelFor(label.sku),
    );
    _inFlight.remove(label.unitId);
    // Acotada a kMaxSessionRecords: la entrega ya quedó en la cola.
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
    return ScanFeedback.ok('Producto entregado · ${label.sku}');
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(carrierScanSessionProvider(_kind));
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear al entregar')),
      body: CarrierScanSessionView(
        records: records,
        emptyIcon: AppIcon.deliverScan,
        emptyTitle: 'Sin entregas registradas',
        emptyMessage:
            'Escanea el producto y el QR del cliente para registrar la entrega.',
        rowIcon: AppIcon.success,
        actionLabel: 'Registrar entrega',
        busy: _busy,
        onAction: _deliver,
      ),
    );
  }
}
