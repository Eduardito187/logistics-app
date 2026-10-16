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

class _ReceptionDetailScreenState extends ConsumerState<ReceptionDetailScreen> {
  bool _busy = false;

  Shipment get _shipment => widget.args.shipment;
  Node get _node => widget.args.node;
  ReceptionKey get _key => (shipmentId: _shipment.id, nodeId: _node.id);

  @override
  Widget build(BuildContext context) {
    final receptionAsync = ref.watch(nodeReceptionProvider(_key));
    return Scaffold(
      appBar: AppBar(title: const Text('Recepción')),
      body: ResponsiveBody(
        child: AsyncValueView<NodeReceptionView?>(
          value: receptionAsync,
          onRetry: () => ref.invalidate(nodeReceptionProvider(_key)),
          data: (view) {
            final isOpen = view?.status == NodeReceptionViewStatus.open;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ReceptionHeader(shipment: _shipment, node: _node),
                      const SizedBox(height: 16),
                      if (view == null)
                        OpenReceptionPanel(
                          shipment: _shipment,
                          node: _node,
                          busy: _busy,
                          onOpen: _openReception,
                        )
                      else
                        ..._receptionBody(context, view),
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
                      label: const Text('Escanear bulto'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _receptionBody(BuildContext context, NodeReceptionView view) {
    // Solo este envío: escaneos de otros envíos no reconstruyen la pantalla.
    final local =
        ref.watch(locallyReceivedProvider.select((m) => m[_shipment.id])) ??
        const <String>{};
    final received = {...view.receivedUnitIds, ...local};
    final expected = view.expectedUnitIds;
    final expectedSet = expected.toSet();
    final pending = expected.where((id) => !received.contains(id)).length;
    final surplus = {
      ...view.surplusUnitIds,
      ...received.where((id) => !expectedSet.contains(id)),
    };
    final isOpen = view.status == NodeReceptionViewStatus.open;

    return [
      ReceptionStats(
        receivedExpected: received.where(expectedSet.contains).length,
        expectedCount: view.expectedCount,
        pending: pending,
        surplusCount: surplus.length,
      ),
      // Abierta: "Escanear bulto" va fijo al pie (ver build).
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
      ReceptionUnitsCard(
        expected: expected,
        received: received,
        surplus: surplus,
      ),
      if (isOpen) ...[
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _confirmReconcile(pending, surplus.length),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Conciliar y cerrar'),
          ),
        ),
      ],
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
      ref.invalidate(nodeReceptionProvider(_key));
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

  Future<void> _scanAndReceive() async {
    final qr = await scanCode(
      context,
      title: 'Escanear bulto',
      helper: 'Apunta al QR de la etiqueta del bulto.',
      formats: const [BarcodeFormat.qrCode],
    );
    if (qr == null || !mounted) return;

    final scan = await resolveUnitScan(ref, qr);
    if (!mounted) return;
    if (scan.verified == false) {
      // Validación de etiqueta en el cliente: la mostramos en rojo con el helper
      // compartido (envuelta como ApiException para reutilizar `showErrorSnack`).
      // Distingue firma inválida de clave desconocida (igual que transportista).
      showErrorSnack(
        context,
        ApiException(
          status: 400,
          title: 'Etiqueta inválida',
          detail: unitScanErrorMessage(scan),
        ),
        bottomClearance: kBottomActionClearance,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final outcome = await ref
          .read(receiveUnitAtNodeProvider)
          .call(
            shipmentId: _shipment.id,
            unitId: scan.unitId,
            destinationNodeId: _node.id,
            customerName: _shipment.customerName,
          );
      ref.read(locallyReceivedProvider.notifier).add(_shipment.id, scan.unitId);
      // Solo re-consultamos al servidor si el escaneo realmente subió; offline
      // el conteo avanza con el estado local y no forzamos una lectura de red.
      if (outcome == SubmitOutcome.sent) {
        ref.invalidate(nodeReceptionProvider(_key));
      }
      if (!mounted) return;
      showSubmitOutcome(
        context,
        outcome,
        bottomClearance: kBottomActionClearance,
      );
      await _askShelfLocation(scan.unitId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askShelfLocation(String unitId) async {
    final location = await showDialog<String>(
      context: context,
      builder: (_) => const ShelfLocationDialog(),
    );
    if (!mounted) return;
    if (location != null && location.isNotEmpty) {
      ref.read(shelfLocationsProvider.notifier).setLocation(unitId, location);
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
      ref.invalidate(nodeReceptionProvider(_key));
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
