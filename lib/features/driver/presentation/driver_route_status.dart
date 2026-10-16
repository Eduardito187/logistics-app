import 'package:flutter/material.dart';

import '../../../core/api/export.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_tone.dart';
import 'stop_detail_screen.dart';

/// Etiqueta en español del estado de la ruta del día.
String routeStatusLabel(DriverRouteStatus status) => switch (status) {
  DriverRouteStatus.planned => 'Planificada',
  DriverRouteStatus.inProgress => 'En curso',
  DriverRouteStatus.completed => 'Completada',
  _ => 'Ruta',
};

/// Color del marcador/avatar según el estado de la parada.
Color stopColor(DriverRouteStopStatus status) => switch (status) {
  DriverRouteStopStatus.completed => AppColors.success,
  DriverRouteStopStatus.failed => AppColors.danger,
  DriverRouteStopStatus.pending => AppColors.info,
  _ => const Color(0xFF607080),
};

/// Etiqueta en español del estado de la parada.
String stopStatusLabel(DriverRouteStopStatus status) => switch (status) {
  DriverRouteStopStatus.completed => 'Entregada',
  DriverRouteStopStatus.failed => 'Fallida',
  DriverRouteStopStatus.pending => 'Pendiente',
  _ => 'Parada',
};

/// Tono del chip según el estado de la parada.
PillTone stopTone(DriverRouteStopStatus status) => switch (status) {
  DriverRouteStopStatus.completed => PillTone.success,
  DriverRouteStopStatus.failed => PillTone.danger,
  DriverRouteStopStatus.pending => PillTone.info,
  _ => PillTone.neutral,
};

/// Abre el detalle de una parada.
void openStopDetail(BuildContext context, DriverRouteStop stop) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => StopDetailScreen(stop: stop)));
}
