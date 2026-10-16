import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/store_controllers.dart';

/// Panel para abrir una recepción que aún no existe: muestra los bultos
/// esperados del envío y pide el nodo de origen para anunciarlos.
class OpenReceptionPanel extends ConsumerStatefulWidget {
  const OpenReceptionPanel({
    super.key,
    required this.shipment,
    required this.node,
    required this.busy,
    required this.onOpen,
  });

  final Shipment shipment;
  final Node node;
  final bool busy;
  final Future<void> Function(Node origin, List<String> expectedUnitIds) onOpen;

  @override
  ConsumerState<OpenReceptionPanel> createState() => _OpenReceptionPanelState();
}

class _OpenReceptionPanelState extends ConsumerState<OpenReceptionPanel> {
  String? _originId;

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(shipmentUnitsProvider(widget.shipment.id));
    final nodesAsync = ref.watch(storeNodesProvider);

    return SectionCard(
      title: 'Abrir recepción',
      child: AsyncValueView<List<UnitTracking>>(
        value: unitsAsync,
        onRetry: () =>
            ref.invalidate(shipmentUnitsProvider(widget.shipment.id)),
        data: (units) {
          final expectedIds = units.map((u) => u.unitId).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Este envío tiene ${expectedIds.length} bulto(s) esperado(s). '
                'Indica el nodo de origen para abrir la recepción.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              nodesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('No se pudieron cargar los nodos.'),
                data: (nodes) {
                  final origins = nodes
                      .where((n) => n.id != widget.node.id)
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _originId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.outbound_outlined),
                      labelText: 'Nodo de origen',
                    ),
                    items: [
                      for (final node in origins)
                        DropdownMenuItem<String>(
                          value: node.id,
                          child: Text('${node.name} · ${node.code}'),
                        ),
                    ],
                    onChanged: (id) => setState(() => _originId = id),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.busy || _originId == null
                      ? null
                      : () {
                          final origin = nodesAsync.value?.firstWhere(
                            (n) => n.id == _originId,
                          );
                          if (origin != null) {
                            widget.onOpen(origin, expectedIds);
                          }
                        },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Abrir recepción'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
