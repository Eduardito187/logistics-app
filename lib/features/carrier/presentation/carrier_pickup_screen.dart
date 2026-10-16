import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/models/scan_request.dart';
import '../../../core/location/location_service.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sync_badge.dart';
import '../domain/usecases/record_load_scan.dart';
import 'widgets/carrier_scan_record.dart';
import 'widgets/carrier_scan_support.dart';
import 'widgets/scan_outcome_pill.dart';

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

  Future<void> _scan() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final label = await scanAndVerifyLabel(
        context,
        ref,
        title: 'Recoger carga',
        helper: 'Apunta al QR de la etiqueta del bulto',
      );
      if (label == null || !mounted) return;

      final gps = await ref.read(locationServiceProvider).current();
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
        title: const Text('Escanear al recoger'),
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
                icon: Icons.upload_file,
                title: 'Sin bultos recogidos',
                message: 'Escanea la etiqueta de cada bulto al cargarlo.',
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
                    leading: const Icon(Icons.inventory_2_outlined),
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
                  onPressed: _busy ? null : _scan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentInk,
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear bulto'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
