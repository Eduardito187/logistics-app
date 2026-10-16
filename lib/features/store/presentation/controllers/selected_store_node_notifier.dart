import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';

/// Nodo de tienda seleccionado como destino de la recepción / mostrador.
final selectedStoreNodeProvider =
    NotifierProvider<SelectedStoreNodeNotifier, Node?>(
      SelectedStoreNodeNotifier.new,
    );

/// Mantiene el nodo (tienda/CD) elegido para el flujo de Tienda.
class SelectedStoreNodeNotifier extends Notifier<Node?> {
  @override
  Node? build() => null;

  void select(Node? node) => state = node;
}
