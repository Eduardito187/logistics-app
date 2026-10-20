import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/proof_of_delivery_request.dart';
import '../../../core/location/location_service.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../domain/usecases/record_proof_of_delivery.dart';
import 'widgets/carrier_scan_record.dart';
import 'widgets/carrier_scan_session_view.dart';
import 'widgets/carrier_scan_support.dart';

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

  Future<void> _deliver() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final label = await scanAndVerifyLabel(
        context,
        ref,
        title: 'Entregar bulto',
        helper: 'Apunta al QR de la etiqueta del bulto',
      );
      if (label == null || !mounted) return;

      // Segundo paso: QR de confirmación del cliente (prueba de entrega).
      final confirmation = await scanCode(
        context,
        title: 'Confirmación del cliente',
        helper: 'Escanea el QR del cliente para confirmar la entrega',
        formats: const [BarcodeFormat.qrCode],
      );
      if (confirmation == null || !mounted) return;

      final gps = await ref.read(locationServiceProvider).current();
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

      if (!mounted) return;
      setState(() {
        _records.insert(
          0,
          CarrierScanRecord(
            unitId: label.unitId,
            title: label.sku,
            outcome: outcome,
            at: now,
          ),
        );
      });
      // El aviso flota encima del botón del pie: no tapa el próximo escaneo.
      showSubmitOutcome(
        context,
        outcome,
        bottomClearance: kBottomActionClearance,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
