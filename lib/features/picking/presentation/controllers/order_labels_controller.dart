import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/emitted_label.dart';
import '../../domain/usecases/get_order_labels.dart';

/// Lectura de las etiquetas vigentes de un pedido (family por número de pedido).
/// Delega en el caso de uso [GetOrderLabels]; la pantalla la consume con
/// `AsyncValueView` y la invalida para refrescar.
final orderLabelsProvider = FutureProvider.family<List<EmittedLabel>, String>((
  ref,
  orderNumber,
) {
  return ref.watch(getOrderLabelsProvider).call(orderNumber);
});
