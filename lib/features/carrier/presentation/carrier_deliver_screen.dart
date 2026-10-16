import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/proof_of_delivery_request.dart';
import '../../../core/location/location_service.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sync_badge.dart';
import '../domain/usecases/record_proof_of_delivery.dart';
import 'widgets/carrier_scan_record.dart';
import 'widgets/carrier_scan_support.dart';
import 'widgets/scan_outcome_pill.dart';

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
      showSubmitOutcome(context, outcome);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.Hm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear al entregar'),
        actions: [
          SyncBadge(onTap: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_records.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.task_alt,
                title: 'Sin entregas registradas',
                message: 'Escanea el bulto y el QR del cliente para registrar la entrega.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return ListTile(
                    tileColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(
                      record.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${record.unitId} · ${timeFormat.format(record.at)}',
                    ),
                    trailing: ScanOutcomePill(record.outcome),
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _deliver,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Registrar entrega'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
