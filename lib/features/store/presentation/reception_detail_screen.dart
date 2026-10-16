import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/sync_badge.dart';
import '../domain/usecases/open_node_reception.dart';
import '../domain/usecases/receive_unit_at_node.dart';
import '../domain/usecases/reconcile_node_reception.dart';
import 'controllers/locally_received_notifier.dart';
import 'controllers/shelf_locations_notifier.dart';
import 'controllers/store_controllers.dart';
import 'unit_scan.dart';
import 'widgets/open_reception_panel.dart';
import 'widgets/reception_units_card.dart';

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
      appBar: AppBar(
        title: const Text('Recepción'),
        actions: [
          SyncBadge(onTap: () => context.push('/sync')),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncValueView<NodeReceptionView?>(
        value: receptionAsync,
        onRetry: () => ref.invalidate(nodeReceptionProvider(_key)),
        data: (view) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(context),
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
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shipment.customerName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pedido ${_shipment.externalId}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'Nodo: ${_node.name} · ${_node.code}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  List<Widget> _receptionBody(BuildContext context, NodeReceptionView view) {
    final localMap = ref.watch(locallyReceivedProvider);
    final local = localMap[_shipment.id] ?? const <String>{};
    final received = {...view.receivedUnitIds, ...local};
    final expected = view.expectedUnitIds;
    final pending = expected.where((id) => !received.contains(id)).length;
    final surplus = {
      ...view.surplusUnitIds,
      ...received.where((id) => !expected.contains(id)),
    };
    final isOpen = view.status == NodeReceptionViewStatus.open;

    return [
      Row(
        children: [
          Expanded(
            child: StatTile(
              value: '${received.length}/${view.expectedCount}',
              label: 'Recibidos',
              icon: Icons.inventory_2,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              value: '$pending',
              label: 'Faltan',
              icon: Icons.hourglass_bottom,
              color: pending == 0 ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
      if (surplus.isNotEmpty) ...[
        const SizedBox(height: 12),
        StatTile(
          value: '${surplus.length}',
          label: 'Sobrantes (no esperados)',
          icon: Icons.report_gmailerrorred,
          color: AppColors.danger,
        ),
      ],
      const SizedBox(height: 16),
      if (isOpen)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _scanAndReceive,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear bulto'),
          ),
        )
      else
        const StatusPill(
          'Recepción conciliada',
          tone: PillTone.success,
          icon: Icons.verified,
        ),
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
      showSuccessSnack(context, 'Recepción abierta.');
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
      showSubmitOutcome(context, outcome);
      await _askShelfLocation(scan.unitId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askShelfLocation(String unitId) async {
    final controller = TextEditingController();
    final location = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubicación en estante'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Dónde se guardó',
            hintText: 'Ej. Pasillo 3 · Estante B2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Omitir'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (location != null && location.isNotEmpty) {
      ref.read(shelfLocationsProvider.notifier).setLocation(unitId, location);
    }
  }

  Future<void> _confirmReconcile(int pending, int surplus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conciliar recepción'),
        content: Text(
          pending == 0 && surplus == 0
              ? 'Todo coincide con el manifiesto. Se cerrará la recepción.'
              : 'Se cerrará la recepción con $pending faltante(s) y '
                    '$surplus sobrante(s). Esta acción queda registrada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Conciliar'),
          ),
        ],
      ),
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
      showErrorSnack(context, e);
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
