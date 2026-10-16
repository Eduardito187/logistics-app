import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/theme/app_colors.dart';
import 'package:logistics_app/core/widgets/pill_tone.dart';
import 'package:logistics_app/features/driver/presentation/driver_route_status.dart';

// Mapeos de estado de la ruta/parada a etiqueta en español, color y tono.

void main() {
  group('routeStatusLabel', () {
    test('cubre los estados definidos', () {
      expect(routeStatusLabel(DriverRouteStatus.planned), 'Planificada');
      expect(routeStatusLabel(DriverRouteStatus.inProgress), 'En curso');
      expect(routeStatusLabel(DriverRouteStatus.completed), 'Completada');
    });

    test('estado desconocido cae en "Ruta"', () {
      expect(routeStatusLabel(DriverRouteStatus.$unknown), 'Ruta');
    });
  });

  group('stopColor', () {
    test('color por estado de parada', () {
      expect(stopColor(DriverRouteStopStatus.completed), AppColors.success);
      expect(stopColor(DriverRouteStopStatus.failed), AppColors.danger);
      expect(stopColor(DriverRouteStopStatus.pending), AppColors.info);
    });

    test('estado desconocido usa el gris neutro', () {
      expect(
        stopColor(DriverRouteStopStatus.$unknown),
        const Color(0xFF607080),
      );
    });
  });

  group('stopStatusLabel', () {
    test('etiqueta por estado de parada', () {
      expect(stopStatusLabel(DriverRouteStopStatus.completed), 'Entregada');
      expect(stopStatusLabel(DriverRouteStopStatus.failed), 'Fallida');
      expect(stopStatusLabel(DriverRouteStopStatus.pending), 'Pendiente');
    });

    test('estado desconocido cae en "Parada"', () {
      expect(stopStatusLabel(DriverRouteStopStatus.$unknown), 'Parada');
    });
  });

  group('stopTone', () {
    test('tono por estado de parada', () {
      expect(stopTone(DriverRouteStopStatus.completed), PillTone.success);
      expect(stopTone(DriverRouteStopStatus.failed), PillTone.danger);
      expect(stopTone(DriverRouteStopStatus.pending), PillTone.info);
    });

    test('estado desconocido usa tono neutro', () {
      expect(stopTone(DriverRouteStopStatus.$unknown), PillTone.neutral);
    });
  });
}
