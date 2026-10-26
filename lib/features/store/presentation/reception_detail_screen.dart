import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/node.dart';
import '../../../core/api/models/node_reception_view.dart';
import '../../../core/api/models/node_reception_view_status.dart';
import '../../../core/api/models/node_type.dart';
import '../../../core/api/models/open_node_reception_request.dart';
import '../../../core/api/models/open_node_reception_request_destination_node_kind.dart';
import '../../../core/api/models/open_node_reception_request_origin_node_kind.dart';
import '../../../core/api/models/reconcile_node_reception_request.dart';
import '../../../core/api/models/shipment.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_pill.dart';
import '../domain/entities/unit_product.dart';
import '../domain/usecases/open_node_reception.dart';
import '../domain/usecases/receive_unit_at_node.dart';
import '../domain/usecases/reconcile_node_reception.dart';
import 'controllers/locally_received_notifier.dart';
import 'controllers/shelf_locations_notifier.dart';
import 'controllers/store_controllers.dart';
import 'unit_scan.dart';
import 'widgets/bottom_action_bar.dart';
import 'widgets/open_reception_panel.dart';
import 'widgets/reception_header.dart';
import 'widgets/reception_stats.dart';
import 'widgets/reception_units_card.dart';
import 'widgets/reconcile_confirm_dialog.dart';
import 'widgets/shelf_location_dialog.dart';

/// Argumentos de navegación a la recepción de un envío en un nodo.
typedef ReceptionArgs = ({Shipment shipment, Node node});

/// Recepción de un envío contra manifiesto en el nodo: abre la recepción,
/// escanea cada bulto que llega, muestra el progreso (recibidos vs esperados) y
/// concilia al cerrar (faltantes/sobrantes).
class ReceptionDetailScreen extends ConsumerStatefulWidget {
  const ReceptionDetailScreen({super.key, required this.args});

  final ReceptionArgs args;

  @override
  ConsumerState<ReceptionDetailScreen> createState() =>
      _ReceptionDetailScreenState();
}

/// Espera tras el último escaneo subido antes de re-leer la recepción del
/// servidor. Durante una ráfaga de escaneos el conteo avanza con el estado
/// local ([locallyReceivedProvider]); recién al terminar se baja la vista real
/// una sola vez (antes: un GET de la recepción entera por bulto).
@visibleForTesting
const Duration kReceptionRefreshDebounce = Duration(seconds: 5);

class _ReceptionDetailScreenState extends ConsumerState<ReceptionDetailScreen> {
  bool _busy = false;

  /// Refresco diferido de la recepción (ver [kReceptionRefreshDebounce]).
  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Reprograma el refresco: cada escaneo subido corre el plazo, así una
  /// ráfaga de N bultos hace un solo GET al final.
  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(kReceptionRefreshDebounce, () {
      _refreshTimer = null;
      if (mounted) ref.invalidate(nodeReceptionProvider(_key));
    });
  }

  /// Refresco inmediato (abrir, conciliar, reintentar): cancela el diferido.
  void _refreshNow() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    ref.invalidate(nodeReceptionProvider(_key));
  }

  Shipment get _shipment => widget.args.shipment;
  Node get _node => widget.args.node;
  ReceptionKey get _key => (shipmentId: _shipment.id, nodeId: _node.id);

  @override
  Widget build(BuildContext context) {
    final receptionAsync = ref.watch(nodeReceptionProvider(_key));
    // Precarga en paralelo con la recepción lo que necesita el panel "Abrir
    // recepción" (bultos y nodos), sin esperar al 404 para pedirlos. `listen`
    // los mantiene vivos sin reconstruir la pantalla cuando llegan.
    if (!receptionAsync.hasValue || receptionAsync.value == null) {
      ref.listen(shipmentUnitsProvider(_shipment.id), (_, _) {});
      ref.listen(storeNodesProvider, (_, _) {});
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Recepción')),
      body: ResponsiveBody(
        child: AsyncValueView<NodeReceptionView?>(
          value: receptionAsync,
          onRetry: _refreshNow,
          data: (view) {
            final isOpen = view?.status == NodeReceptionViewStatus.open;
            return Column(
              children: [
                // Slivers: la lista de productos es perezosa (ver
                // ReceptionUnitsCard); con 100+ productos con foto solo se
                // arman y decodifican las filas visibles.
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            SliverToBoxAdapter(
                              child: ReceptionHeader(
                                shipment: _shipment,
                                node: _node,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                            if (view == null)
                              SliverToBoxAdapter(
                                child: OpenReceptionPanel(
                                  shipment: _shipment,
                                  node: _node,
                                  busy: _busy,
                                  onOpen: _openReception,
                                ),
                              )
                            else
                              ..._receptionBody(context, view),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Escaneo seguido: el botón queda fijo al pie, a mano del
                // pulgar, y los avisos flotan encima (kBottomActionClearance).
                if (isOpen)
                  BottomActionBar(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _scanAndReceive,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear producto'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Conteos de la recepción, recalculados solo cuando cambia la vista del
  /// servidor o lo recibido localmente (no en cada `setState` de `_busy`, que
  /// pasa dos veces por escaneo).
  _ReceptionTally? _tally;

  _ReceptionTally _tallyFor(NodeReceptionView view, Set<String> local) {
    final cached = _tally;
    if (cached != null &&
        identical(cached.view, view) &&
        identical(cached.local, local)) {
      return cached;
    }
    return _tally = _ReceptionTally(view, local);
  }

  List<Widget> _receptionBody(BuildContext context, NodeReceptionView view) {
    // Solo este envío: escaneos de otros envíos no reconstruyen la pantalla.
    final local =
        ref.watch(locallyReceivedProvider.select((m) => m[_shipment.id])) ??
        const <String>{};
    final tally = _tallyFor(view, local);
    final isOpen = view.status == NodeReceptionViewStatus.open;

    return [
      SliverList.list(
        children: [
          ReceptionStats(
            receivedExpected: tally.receivedExpected,
            expectedCount: view.expectedCount,
            pending: tally.pending,
            surplusCount: tally.surplus.length,
          ),
          // Abierta: "Escanear producto" va fijo al pie (ver build).
          if (!isOpen) ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                'Recepción conciliada',
                tone: PillTone.success,
                icon: Icons.verified,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
      ReceptionUnitsCard(
        expected: view.expectedUnitIds,
        received: tally.received,
        surplus: tally.surplus,
        products: tally.products,
      ),
      if (isOpen)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _confirmReconcile(
                        tally.pending,
                        tally.surplus.length,
                      ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Conciliar y cerrar'),
              ),
            ),
          ),
        ),
    ];
  }

  Future<void> _openReception(Node origin, List<String> expectedUnitIds) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(openNodeReceptionProvider)
          .call(
            OpenNodeReceptionRequest(
              shipmentId: _shipment.id,
              originNodeId: origin.id,
              destinationNodeId: _node.id,
              originNodeKind: _originKind(origin.type),
              destinationNodeKind: _destinationKind(_node.type),
              expectedUnitIds: expectedUnitIds,
              occurredAt: DateTime.now(),
            ),
          );
      _refreshNow();
      if (!mounted) return;
      showSuccessSnack(
        context,
        'Recepción abierta.',
        bottomClearance: kBottomActionClearance,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Escaneo CONTINUO: la cámara queda abierta y cada producto se recibe al
  /// leerlo (aviso verde/rojo sobre la cámara). Al terminar la ráfaga se pide
  /// una sola vez la ubicación en estante para todo lo recibido.
  Future<void> _scanAndReceive() async {
    // El GPS se calienta junto con la cámara: al leer cada código ya suele
    // haber fix y el registro no lo espera aparte.
    warmUpLocation(ref);
    final registered = <String>[];
    setState(() => _busy = true);
    try {
      await scanContinuous(
        context,
        title: 'Escanear producto',
        helper: 'Apunta al QR de la etiqueta del producto.',
        formats: const [BarcodeFormat.qrCode],
        onCode: (qr) => _receiveCode(qr, registered),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || registered.isEmpty) return;
    showSuccessSnack(
      context,
      registered.length == 1
          ? '1 producto recibido.'
          : '${registered.length} productos recibidos.',
      bottomClearance: kBottomActionClearance,
    );
    await _askShelfLocation(registered);
  }

  /// Procesa un código de la ráfaga. Los registrados (no rechazados) se suman a
  /// [registered] para el diálogo de estante del final.
  Future<ScanFeedback> _receiveCode(String qr, List<String> registered) async {
    final scan = await resolveUnitScan(ref, qr);
    if (!mounted) return const ScanFeedback.error('Pantalla cerrada');
    // Validación de etiqueta en el cliente (offline): firma inválida o clave
    // desconocida, igual que transportista.
    if (scan.verified == false) {
      return ScanFeedback.error(unitScanShortError(scan));
    }

    final view = ref.read(nodeReceptionProvider(_key)).value;
    final local = ref.read(locallyReceivedProvider.notifier);
    final unitId = scan.unitId;
    final already =
        local.forShipment(_shipment.id).contains(unitId) ||
        (view?.receivedUnitIds.contains(unitId) ?? false) ||
        (view?.surplusUnitIds.contains(unitId) ?? false);
    if (already) return const ScanFeedback.error('Ya recibido');
    final expected = view == null || view.expectedUnitIds.contains(unitId);

    // Feedback inmediato: el conteo avanza apenas se lee el código, sin
    // esperar al registro (que se guarda local y sube por la cola).
    local.add(_shipment.id, unitId);
    final outcome = await ref
        .read(receiveUnitAtNodeProvider)
        .call(
          shipmentId: _shipment.id,
          unitId: unitId,
          destinationNodeId: _node.id,
          customerName: _shipment.customerName,
          location: prefetchFix(ref),
        );
    if (outcome == SubmitOutcome.failed) {
      // Rechazado por el backend (error de datos): no cuenta como recibido.
      local.remove(_shipment.id, unitId);
      return ScanFeedback.error(submitOutcomeMessage(outcome));
    }
    // Solo se re-consulta al servidor si el escaneo realmente subió, y con
    // debounce: una ráfaga de escaneos hace un único GET al final.
    if (outcome == SubmitOutcome.sent) _scheduleRefresh();
    registered.add(unitId);
    // Regla de recepción contra manifiesto: el sobrante se registra igual
    // (la conciliación lo reporta), pero se avisa en rojo para apartarlo.
    if (!expected) return const ScanFeedback.error('No es de este pedido');
    if (view == null) return const ScanFeedback.ok('Producto recibido');
    final all = {...view.receivedUnitIds, ...local.forShipment(_shipment.id)};
    final done = view.expectedUnitIds.where(all.contains).length;
    return ScanFeedback.ok('Producto recibido ($done/${view.expectedCount})');
  }

  /// Una sola ubicación para todo lo recibido en la ráfaga (ver
  /// [ShelfLocationDialog]); "Omitir" no guarda nada.
  Future<void> _askShelfLocation(List<String> unitIds) async {
    final location = await showDialog<String>(
      context: context,
      builder: (_) => ShelfLocationDialog(count: unitIds.length),
    );
    if (!mounted) return;
    if (location != null && location.isNotEmpty) {
      final shelves = ref.read(shelfLocationsProvider.notifier);
      for (final id in unitIds) {
        shelves.setLocation(id, location);
      }
    }
  }

  Future<void> _confirmReconcile(int pending, int surplus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          ReconcileConfirmDialog(pending: pending, surplus: surplus),
    );
    if (confirmed != true) return;
    await _reconcile();
  }

  Future<void> _reconcile() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(reconcileNodeReceptionProvider)
          .call(
            ReconcileNodeReceptionRequest(
              shipmentId: _shipment.id,
              destinationNodeId: _node.id,
              occurredAt: DateTime.now(),
            ),
          );
      // Cerrada: lo recibido localmente ya no hace falta (el servidor manda).
      ref.read(locallyReceivedProvider.notifier).clear(_shipment.id);
      _refreshNow();
      if (!mounted) return;
      showSuccessSnack(context, 'Recepción conciliada y cerrada.');
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e, bottomClearance: kBottomActionClearance);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static OpenNodeReceptionRequestOriginNodeKind _originKind(NodeType type) =>
      type == NodeType.store
      ? OpenNodeReceptionRequestOriginNodeKind.store
      : OpenNodeReceptionRequestOriginNodeKind.cd;

  static OpenNodeReceptionRequestDestinationNodeKind _destinationKind(
    NodeType type,
  ) => type == NodeType.store
      ? OpenNodeReceptionRequestDestinationNodeKind.store
      : OpenNodeReceptionRequestDestinationNodeKind.cd;
}

/// Conteos derivados de una recepción (servidor + recibido local).
class _ReceptionTally {
  _ReceptionTally(this.view, this.local) {
    final all = {...view.receivedUnitIds, ...local};
    final expectedSet = view.expectedUnitIds.toSet();
    received = all;
    pending = view.expectedUnitIds.where((id) => !all.contains(id)).length;
    receivedExpected = all.where(expectedSet.contains).length;
    surplus = {
      ...view.surplusUnitIds,
      ...all.where((id) => !expectedSet.contains(id)),
    };
    products = receptionProducts(view.units);
  }

  final NodeReceptionView view;
  final Set<String> local;
  late final Set<String> received;
  late final int pending;
  late final int receivedExpected;
  late final Set<String> surplus;
  late final Map<String, UnitProduct> products;
}
