import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/selected_store_node_notifier.dart';
import '../controllers/store_controllers.dart';

/// Selector del nodo destino (tienda/CD). Guarda la elección para el resto del
/// flujo. Trabaja por id para resistir recargas de la lista de nodos.
class StoreSelector extends ConsumerWidget {
  const StoreSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(storeNodesProvider);
    final selected = ref.watch(selectedStoreNodeProvider);
    return SectionCard(
      title: 'Tienda / nodo',
      child: AsyncValueView<List<Node>>(
        value: nodesAsync,
        onRetry: () => ref.invalidate(storeNodesProvider),
        data: (nodes) {
          if (nodes.isEmpty) {
            return const Text('No hay nodos activos en la red.');
          }
          return DropdownButtonFormField<String>(
            initialValue: selected?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.place_outlined),
              hintText: 'Selecciona el nodo donde estás',
            ),
            items: [
              for (final node in nodes)
                DropdownMenuItem<String>(
                  value: node.id,
                  child: Text('${node.name}  ·  ${node.code}'),
                ),
            ],
            onChanged: (id) {
              if (id == null) return;
              final node = nodes.firstWhere((n) => n.id == id);
              ref.read(selectedStoreNodeProvider.notifier).select(node);
            },
          );
        },
      ),
    );
  }
}
