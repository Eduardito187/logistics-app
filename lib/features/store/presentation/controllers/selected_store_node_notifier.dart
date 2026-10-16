import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/auth/session.dart';

/// Tienda del usuario: la asignada en el backend (`/app/auth/me` → `node`).
/// El rol tienda NO elige tienda: solo recibe y entrega en la suya (el backend
/// rechaza con 403 cualquier otro nodo). `null` = sin tienda asignada.
final selectedStoreNodeProvider = Provider<Node?>(
  (ref) => ref.watch(sessionProvider.select((s) => s?.storeNode)),
);
