import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/emitted_label.dart';
import '../../domain/usecases/get_order_labels.dart';

/// Lectura de las etiquetas vigentes de un pedido (family por número de pedido).
/// Delega en el caso de uso [GetOrderLabels]; la pantalla la consume con
/// `AsyncValueView` y la invalida para refrescar.
///
/// `autoDispose`: solo la usa la pantalla de armado del pedido, y cada etiqueta
/// trae su ZPL (varios KB). Sin esto quedaban en memoria las etiquetas de TODOS
/// los pedidos abiertos en el turno (fuga de memoria y datos viejos); al cerrar
/// la pantalla se libera y se recarga fresca al volver, igual que el resto de
/// lecturas (tienda/transportista) y que el pull-to-refresh.
final orderLabelsProvider = FutureProvider.autoDispose
    .family<List<EmittedLabel>, String>((ref, orderNumber) {
      return ref.watch(getOrderLabelsProvider).call(orderNumber);
    });
