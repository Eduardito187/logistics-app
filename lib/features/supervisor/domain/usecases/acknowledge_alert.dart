import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Command: reconoce una alerta de telemetría (requiere red).
class AcknowledgeAlert {
  const AcknowledgeAlert(this._repo);

  final SupervisorRepository _repo;

  Future<void> call(String alertId) => _repo.acknowledgeTelemetryAlert(alertId);
}

final acknowledgeAlertProvider = Provider<AcknowledgeAlert>(
  (ref) => AcknowledgeAlert(ref.watch(supervisorRepositoryProvider)),
);
