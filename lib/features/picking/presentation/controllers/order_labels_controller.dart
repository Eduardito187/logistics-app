import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/emitted_label.dart';
import '../../domain/usecases/get_order_labels.dart';

/// Lectura de las etiquetas vigentes de un pedido (family por número de pedido).
/// Delega en el caso de uso [GetOrderLabels]; la pantalla la consume con
/// `AsyncValueView` y la invalida para refrescar.
///
/// `autoDispose`: cada etiqueta trae su ZPL (varios KB); sin esto quedaban en
/// memoria las etiquetas de TODOS los pedidos abiertos en el turno. Al volver
/// al pedido se vuelven a pedir (y el pull-to-refresh ya hacía lo mismo).
final orderLabelsProvider = FutureProvider.autoDispose
    .family<List<EmittedLabel>, String>((ref, orderNumber) {
      return ref.watch(getOrderLabelsProvider).call(orderNumber);
    });
