import '../../../../core/api/export.dart';
import 'due_maintenance_urgency.dart';

// Reexporta la urgencia para no romper a quienes ya importan esta entidad.
export 'due_maintenance_urgency.dart';

/// Item de mantenimiento por vencer, leído de forma tolerante del objeto libre
/// del backend. Es una entidad del cliente: deriva su propia urgencia (invariante
/// de dominio). Solo lectura: el chofer lo consulta, no lo edita.
class DueMaintenanceItem {
  const DueMaintenanceItem({
    this.vehicleId,
    this.plate,
    this.serviceKind,
    this.nextDueAt,
    this.nextDueKm,
    this.currentKm,
    this.remainingKm,
    this.remainingDays,
    required this.overdue,
  });

  factory DueMaintenanceItem.fromMap(Map<String, Object?> map) {
    final remainingDays = _asInt(map['remaining_days']);
    final remainingKm = _asInt(map['remaining_km']);
    final overdue =
        (map['overdue'] as bool?) ??
        ((remainingDays != null && remainingDays < 0) ||
            (remainingKm != null && remainingKm < 0));
    return DueMaintenanceItem(
      vehicleId: map['vehicle_id'] as String?,
      plate: (map['plate'] ?? map['vehicle_plate']) as String?,
      serviceKind: map['service_kind'] is String
          ? MaintenancePlanServiceKind.fromJson(map['service_kind'] as String)
          : null,
      nextDueAt: _asDate(map['next_due_at']),
      nextDueKm: _asInt(map['next_due_km']),
      currentKm: _asInt(map['current_km']),
      remainingKm: remainingKm,
      remainingDays: remainingDays,
      overdue: overdue,
    );
  }

  final String? vehicleId;
  final String? plate;
  final MaintenancePlanServiceKind? serviceKind;
  final DateTime? nextDueAt;
  final int? nextDueKm;
  final int? currentKm;
  final int? remainingKm;
  final int? remainingDays;
  final bool overdue;

  /// Urgencia derivada: vencido, por vencer (≤7 días o ≤500 km) o programado.
  DueMaintenanceUrgency get urgency {
    if (overdue) return DueMaintenanceUrgency.overdue;
    final days = remainingDays ?? _daysUntil(nextDueAt);
    if ((days != null && days <= 0) ||
        (remainingKm != null && remainingKm! <= 0)) {
      return DueMaintenanceUrgency.overdue;
    }
    if ((days != null && days <= 7) ||
        (remainingKm != null && remainingKm! <= 500)) {
      return DueMaintenanceUrgency.dueSoon;
    }
    return DueMaintenanceUrgency.scheduled;
  }

  static int? _daysUntil(DateTime? date) {
    if (date == null) return null;
    return date.difference(DateTime.now()).inDays;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _asDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
