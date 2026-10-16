/// Urgencia de un mantenimiento por vencer, de más a menos crítico.
enum DueMaintenanceUrgency { overdue, dueSoon, scheduled }

extension DueMaintenanceUrgencyX on DueMaintenanceUrgency {
  /// Orden para ordenar (0 = más urgente).
  int get order => switch (this) {
    DueMaintenanceUrgency.overdue => 0,
    DueMaintenanceUrgency.dueSoon => 1,
    DueMaintenanceUrgency.scheduled => 2,
  };
}
