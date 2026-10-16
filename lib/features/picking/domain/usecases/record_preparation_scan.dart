import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/preparation_scan_request.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Command, CQRS): registra la preparación de una unidad.
/// Offline-first: el repositorio lo encola vía `offlineQueueProvider.submit`
/// con ID idempotente y devuelve el [SubmitOutcome] de la cola.
class RecordPreparationScan {
  const RecordPreparationScan(this._repo);

  final PickingRepository _repo;

  Future<SubmitOutcome> call(PreparationScanRequest scan) =>
      _repo.recordPreparationScan(scan);
}

final recordPreparationScanProvider = Provider<RecordPreparationScan>(
  (ref) => RecordPreparationScan(ref.watch(pickingRepositoryProvider)),
);
