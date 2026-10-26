import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/export.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/scanning/continuous_scanner.dart';
import '../../../core/theme/code_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/locally_loaded_units.dart';
import 'driver_common.dart';
import 'scan_mode.dart';
import 'scanned_unit.dart';

/// Escaneo de bultos para carga (al camión) o descarga (por parada) en modo
/// CONTINUO: la cámara queda abierta entre bultos y cada lectura muestra su
/// aviso verde/rojo encima ("Bulto 3/5 cargado", "Ya registrado"...). Cada
/// bulto se registra local con id idempotente y se sincroniza después; nunca
/// espera a la red.
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

  /// Bultos registrados (no fallidos) en esta pantalla.
  final Set<String> _registered = {};
  bool _busy = false;

  /// Mantiene viva la lista de bultos esperados mientras se escanea.
  ProviderSubscription<AsyncValue<Set<String>>>? _expectedSub;

  bool get _isLoad => widget.mode == ScanMode.load;

  @override
  void initState() {
    super.initState();
    // GPS caliente antes del primer bulto: cada registro toma el último fix
    // sin prender el GPS por bulto.
    ref.read(locationServiceProvider).prefetch();
    // Bultos esperados del envío, sin esperarlos (offline-first).
    _expectedSub = ref.listenManual(
      driverShipmentUnitsProvider(widget.shipmentId),
      (_, _) {},
    );
  }

  @override
  void dispose() {
    _expectedSub?.close();
    super.dispose();
  }

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
                      '${_registered.length} bulto(s) registrados',
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
                        onPressed: _busy ? null : _scanSession,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          _isLoad
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

  /// Abre la cámara continua: se escanean todos los bultos seguidos y se
  /// vuelve con "Terminar".
  Future<void> _scanSession() async {
    setState(() => _busy = true);
    try {
      await scanContinuous(
        context,
        title: _isLoad ? 'Cargar bultos' : 'Descargar bultos',
        helper: 'Apunta al QR de cada bulto',
        formats: const [BarcodeFormat.qrCode],
        onCode: _onCode,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Procesa un código leído: verifica la etiqueta offline, valida que el
  /// bulto sea de este envío y que no esté repetido, y lo encola.
  Future<ScanFeedback> _onCode(String qr) async {
    final unitId = await verifyUnitLabel(ref, qr);
    if (unitId == null) return const ScanFeedback.error('Etiqueta inválida');
    if (!mounted) return const ScanFeedback.error(_closed);

    final expected = ref
        .read(driverShipmentUnitsProvider(widget.shipmentId))
        .value;
    if (expected != null && !expected.contains(unitId)) {
      return ScanFeedback.error(
        _isLoad
            ? 'Ese bulto no es de este camión'
            : 'Ese bulto no es de esta parada',
      );
    }
    if (_alreadyRegistered(unitId)) {
      return const ScanFeedback.error('Ya registrado');
    }

    final fix = await currentFix(ref);
    if (!mounted) return const ScanFeedback.error(_closed);
    final outcome = await _submit(unitId, fix);
    if (!mounted) return const ScanFeedback.error(_closed);

    final failed = outcome == SubmitOutcome.failed;
    if (!failed && _isLoad) {
      // La pantalla de Carga muestra el conteo al volver aunque el escaneo
      // siga en la cola offline.
      ref
          .read(locallyLoadedUnitsProvider.notifier)
          .add(widget.shipmentId, unitId);
    }
    setState(() {
      // Un reintento de un bulto fallido reemplaza su fila.
      _scanned.removeWhere((s) => s.unitId == unitId);
      _scanned.add(ScannedUnit(unitId, outcome));
      if (!failed) _registered.add(unitId);
    });
    if (failed) {
      return const ScanFeedback.error('No se pudo registrar. Reintentá.');
    }
    final total = expected?.length;
    final count = _registeredCount();
    final verb = _isLoad ? 'cargado' : 'descargado';
    return ScanFeedback.ok(
      total == null ? 'Bulto $count $verb' : 'Bulto $count/$total $verb',
    );
  }

  static const String _closed = 'Escaneo cerrado';

  /// Ya registrado en esta pantalla o (carga) antes en este teléfono.
  bool _alreadyRegistered(String unitId) {
    if (_registered.contains(unitId)) return true;
    if (!_isLoad) return false;
    final local = ref.read(locallyLoadedUnitsProvider)[widget.shipmentId];
    return local != null && local.contains(unitId);
  }

  /// Bultos del envío registrados: en carga incluye los cargados antes en este
  /// teléfono (otra pasada por la pantalla).
  int _registeredCount() {
    if (!_isLoad) return _registered.length;
    final local = ref.read(locallyLoadedUnitsProvider)[widget.shipmentId];
    return {...?local, ..._registered}.length;
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
      title: CodeText(
        item.unitId,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: StatusPill(
        failed ? 'Error' : 'Registrado',
        tone: failed ? PillTone.danger : PillTone.success,
      ),
    );
  }
}
