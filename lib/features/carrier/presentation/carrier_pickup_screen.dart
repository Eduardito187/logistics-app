import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/scan_request.dart';
import '../../../core/location/location_service.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack.dart';
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
