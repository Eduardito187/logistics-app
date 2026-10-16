import 'package:intl/intl.dart';

/// Formateadores de presentación para dispositivos/sesiones, compartidos entre
/// la pantalla "Mis dispositivos" y la tarjeta de dispositivo.
final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'es');

/// Fecha y hora legibles, en hora local. `null` → guion.
String formatDeviceDateTime(DateTime? date) {
  if (date == null) return '—';
  return _dateTimeFormat.format(date.toLocal());
}

/// Etiqueta legible de la plataforma del dispositivo.
String platformLabel(String? platform) {
  switch (platform?.toLowerCase()) {
    case 'android':
      return 'Android';
    case 'ios':
      return 'iOS';
    case 'web':
      return 'Web';
    case null:
    case '':
      return 'Dispositivo';
    default:
      return platform!;
  }
}
