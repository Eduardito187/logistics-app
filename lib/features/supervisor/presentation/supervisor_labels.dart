import 'package:intl/intl.dart';

import '../../../core/api/models/alert_severity.dart';
import '../../../core/api/models/alert_type.dart';
import '../../../core/api/models/plan_status.dart';
import '../../../core/api/models/planned_stop.dart';
import '../../../core/widgets/status_pill.dart';

/// Etiquetas y mapeos a tono de color para los enums de la API, en español.

String alertTypeLabel(AlertType type) => switch (type) {
  AlertType.afterHoursMovement => 'Movimiento fuera de horario',
  AlertType.excessiveIdle => 'Ralentí excesivo',
  AlertType.geofenceViolation => 'Violación de geocerca',
  AlertType.unauthorizedUse => 'Uso no autorizado',
  AlertType.speeding => 'Exceso de velocidad',
  AlertType.$unknown => 'Alerta de telemetría',
};

String alertSeverityLabel(AlertSeverity severity) => switch (severity) {
  AlertSeverity.info => 'Informativa',
  AlertSeverity.warning => 'Advertencia',
  AlertSeverity.critical => 'Crítica',
  AlertSeverity.$unknown => 'Alerta',
};

PillTone alertSeverityTone(AlertSeverity severity) => switch (severity) {
  AlertSeverity.info => PillTone.info,
  AlertSeverity.warning => PillTone.warning,
  AlertSeverity.critical => PillTone.danger,
  AlertSeverity.$unknown => PillTone.neutral,
};

String planStatusLabel(PlanStatus status) => switch (status) {
  PlanStatus.draft => 'Borrador',
  PlanStatus.proposed => 'Propuesto',
  PlanStatus.published => 'Publicado',
  PlanStatus.$unknown => 'Desconocido',
};

PillTone planStatusTone(PlanStatus status) => switch (status) {
  PlanStatus.draft => PillTone.neutral,
  PlanStatus.proposed => PillTone.warning,
  PlanStatus.published => PillTone.success,
  PlanStatus.$unknown => PillTone.neutral,
};

final DateFormat _hourFormat = DateFormat('HH:mm');
final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

/// Hora corta `HH:mm` en horario local.
String formatHour(DateTime value) => _hourFormat.format(value.toLocal());

/// Fecha `dd/MM/yyyy` en horario local.
String formatDay(DateTime value) => _dayFormat.format(value.toLocal());

/// ETA final del plan: la hora de llegada MÁS TARDÍA entre sus paradas (cuando
/// la ruta queda completa). `null` si ninguna parada tiene ETA. Criterio único
/// y robusto, compartido por la tarjeta de resumen y el detalle del plan, para
/// que nunca muestren una "ETA final" distinta para el mismo plan.
DateTime? planFinalEta(Iterable<PlannedStop> stops) {
  DateTime? latest;
  for (final stop in stops) {
    final eta = stop.etaAt;
    if (eta != null && (latest == null || eta.isAfter(latest))) {
      latest = eta;
    }
  }
  return latest;
}

/// Texto legible para el detalle libre (`dynamic`) de una alerta, acotando el
/// tipo dinámico a este único punto.
String? alertDetailText(Object? detail) {
  if (detail == null) return null;
  if (detail is String) return detail.isEmpty ? null : detail;
  if (detail is num || detail is bool) return '$detail';
  if (detail is Map) {
    final parts = <String>[];
    detail.forEach((key, value) => parts.add('$key: $value'));
    return parts.isEmpty ? null : parts.join(' · ');
  }
  return null;
}
