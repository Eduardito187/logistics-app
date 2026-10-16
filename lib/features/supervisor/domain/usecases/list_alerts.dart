import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: alertas de telemetría. Si `unacknowledgedOnly` es `true` se piden
/// solo las no reconocidas (abiertas); si no, se piden todas.
class ListAlerts {
  const ListAlerts(this._repo);

  final SupervisorRepository _repo;

  Future<List<Alert>> call({required bool unacknowledgedOnly}) => _repo
      .listTelemetryAlerts(acknowledged: unacknowledgedOnly ? false : null);
}

final listAlertsProvider = Provider<ListAlerts>(
  (ref) => ListAlerts(ref.watch(supervisorRepositoryProvider)),
);
