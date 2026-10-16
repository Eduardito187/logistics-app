import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'offline_queue.dart';

/// Stream de la cola local (acciones pendientes/fallidas). Uso interno: la UI
/// de campo no muestra el estado offline (ver `SyncNotice` en app.dart).
final syncQueueProvider = StreamProvider<List<OutboxAction>>(
  (ref) => ref.watch(offlineQueueProvider).watchQueue(),
);
