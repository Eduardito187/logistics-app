import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import 'driver_common.dart';
import 'scan_mode.dart';
import 'scanned_unit.dart';

/// Escaneo repetido de bultos para carga (al camión) o descarga (por parada).
/// Cada escaneo se registra local con id idempotente y se sincroniza después;
/// nunca espera a la red.
class ScanUnitsScreen extends ConsumerStatefulWidget {
  const ScanUnitsScreen({
    super.key,
    required this.mode,
    required this.shipmentId,
    required this.title,
    this.nodeId,
  });

  final ScanMode mode;
  final String shipmentId;
  final String title;

  /// Parada (nodo) donde se descarga; requerido en modo descarga.
  final String? nodeId;

  @override
  ConsumerState<ScanUnitsScreen> createState() => _ScanUnitsScreenState();
}

class _ScanUnitsScreenState extends ConsumerState<ScanUnitsScreen> {
  final List<ScannedUnit> _scanned = [];
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ResponsiveBody(
        child: Column(
          children: [
            Expanded(
              child: _scanned.isEmpty
                  // Centrado y con scroll: en teléfonos chicos con letra grande
                  // el estado vacío no se desborda.
                  ? const Center(
                      child: SingleChildScrollView(
                        child: EmptyState(
                          icon: Icons.qr_code_scanner,
                          title: 'Sin bultos',
                          message: 'Escanea el primer bulto para empezar.',
                        ),
                      ),
                    )
                  // builder: con cientos de bultos solo se construyen las
                  // filas visibles (memoria acotada en teléfonos de 1 GB).
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _scanned.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) =>
                          _ScannedTile(item: _scanned[_scanned.length - 1 - i]),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${_scanned.length} bulto(s) registrados',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: _busy ? null : _scanOne,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          widget.mode == ScanMode.load
                              ? 'Escanear bulto para cargar'
                              : 'Escanear bulto para descargar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanOne() async {
    setState(() => _busy = true);
    try {
      // El botón de escanear está fijo al pie: los avisos flotan encima para
      // no taparlo en escaneos seguidos.
      final unitId = await scanVerifiedUnit(
        context,
        ref,
        bottomClearance: kBottomActionClearance,
      );
      if (unitId == null || !mounted) return;
      final fix = await currentFix(ref);
      if (!mounted) return;
      final outcome = await _submit(unitId, fix);
      if (!mounted) return;
      setState(() => _scanned.add(ScannedUnit(unitId, outcome)));
      showSubmitOutcome(
        context,
        outcome,
        bottomClearance: kBottomActionClearance,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<SubmitOutcome> _submit(String unitId, GpsFix? fix) {
    final queue = ref.read(offlineQueueProvider);
    final now = DateTime.now();
    final lat = fix?.lat ?? 0;
    final lng = fix?.lng ?? 0;
    if (widget.mode == ScanMode.load) {
      return queue.submit(
        kind: 'recordLoadScan',
        payload: ScanRequest(
          shipmentId: widget.shipmentId,
          unitId: unitId,
          lat: lat,
          lng: lng,
          occurredAt: now,
        ).toJson(),
        label: 'Carga · $unitId',
        occurredAt: now,
      );
    }
    return queue.submit(
      kind: 'recordUnloadScan',
      payload: UnloadScanRequest(
        shipmentId: widget.shipmentId,
        unitId: unitId,
        lat: lat,
        lng: lng,
        occurredAt: now,
        nodeId: widget.nodeId ?? widget.shipmentId,
      ).toJson(),
      label: 'Descarga · $unitId',
      occurredAt: now,
    );
  }
}

/// Fila de un bulto escaneado. Offline invisible: lo encolado se muestra igual
/// que lo enviado (la cola sube todo por debajo).
class _ScannedTile extends StatelessWidget {
  const _ScannedTile({required this.item});

  final ScannedUnit item;

  @override
  Widget build(BuildContext context) {
    final failed = item.outcome == SubmitOutcome.failed;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2),
      title: Text(item.unitId, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: StatusPill(
        failed ? 'Error' : 'Registrado',
        tone: failed ? PillTone.danger : PillTone.success,
      ),
    );
  }
}
