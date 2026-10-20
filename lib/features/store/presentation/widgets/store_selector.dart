import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/section_card.dart';
import '../controllers/selected_store_node_notifier.dart';

/// Tienda del usuario, fija y no editable (la asigna el supervisor en el
/// admin). Reemplaza al antiguo selector de nodos.
class StoreSelector extends ConsumerWidget {
  const StoreSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = ref.watch(selectedStoreNodeProvider);
    return SectionCard(
      title: 'Tu tienda',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.storefront),
        title: Text(node?.name ?? 'Sin tienda asignada'),
        subtitle: Text(
          node == null
              ? 'Contactá a tu supervisor para que te asigne una tienda.'
              : node.code,
        ),
      ),
    );
  }
}
