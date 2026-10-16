import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/alert_severity.dart';
import 'package:logistics_app/core/api/models/alert_type.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_labels.dart';

// Etiquetas, tonos y formato de fechas del supervisor. Lógica pura de
// presentación; el formato de fecha usa un patrón fijo (no depende del locale).

void main() {
  group('etiquetas de alerta', () {
    test('traduce el tipo de alerta', () {
      expect(
        alertTypeLabel(AlertType.afterHoursMovement),
        'Movimiento fuera de horario',
      );
      expect(alertTypeLabel(AlertType.excessiveIdle), 'Ralentí excesivo');
      expect(
        alertTypeLabel(AlertType.geofenceViolation),
        'Violación de geocerca',
      );
      expect(alertTypeLabel(AlertType.unauthorizedUse), 'Uso no autorizado');
      expect(alertTypeLabel(AlertType.speeding), 'Exceso de velocidad');
      expect(alertTypeLabel(AlertType.$unknown), 'Alerta de telemetría');
    });

    test('traduce la severidad y su tono', () {
      expect(alertSeverityLabel(AlertSeverity.info), 'Informativa');
      expect(alertSeverityLabel(AlertSeverity.critical), 'Crítica');
      expect(alertSeverityTone(AlertSeverity.info), PillTone.info);
      expect(alertSeverityTone(AlertSeverity.warning), PillTone.warning);
      expect(alertSeverityTone(AlertSeverity.critical), PillTone.danger);
      expect(alertSeverityTone(AlertSeverity.$unknown), PillTone.neutral);
    });
  });

  group('etiquetas de plan', () {
    test('traduce el estado del plan y su tono', () {
      expect(planStatusLabel(PlanStatus.draft), 'Borrador');
      expect(planStatusLabel(PlanStatus.proposed), 'Propuesto');
      expect(planStatusLabel(PlanStatus.published), 'Publicado');
      expect(planStatusTone(PlanStatus.published), PillTone.success);
      expect(planStatusTone(PlanStatus.proposed), PillTone.warning);
      expect(planStatusTone(PlanStatus.draft), PillTone.neutral);
    });
  });

  group('formato de fecha y hora', () {
    test('formatDay usa dd/MM/yyyy', () {
      expect(formatDay(DateTime(2026, 3, 9)), '09/03/2026');
    });

    test('formatHour usa HH:mm en 24h', () {
      expect(formatHour(DateTime(2026, 3, 9, 14, 5)), '14:05');
    });
  });

  group('alertDetailText', () {
    test('null o cadena vacía devuelven null', () {
      expect(alertDetailText(null), isNull);
      expect(alertDetailText(''), isNull);
    });

    test('cadena no vacía se devuelve tal cual', () {
      expect(alertDetailText('abc'), 'abc');
    });

    test('números y booleanos se vuelven texto', () {
      expect(alertDetailText(42), '42');
      expect(alertDetailText(true), 'true');
    });

    test('un mapa se concatena clave: valor', () {
      expect(alertDetailText({'kmh': 90, 'max': 60}), 'kmh: 90 · max: 60');
    });

    test('un mapa vacío devuelve null', () {
      expect(alertDetailText(const <String, Object?>{}), isNull);
    });
  });
}
