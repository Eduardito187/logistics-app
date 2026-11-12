import 'package:intl/intl.dart';

/// Formateadores de presentación para dispositivos/sesiones, compartidos entre
/// la pantalla "Mis dispositivos" y la tarjeta de dispositivo.
final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'es');

/// Fecha y hora legibles, en hora local. `null` → guion.
String formatDeviceDateTime(DateTime? date) {
  if (date == null) return '—';
  return _dateTimeFormat.format(date.toLocal());
}

/// Nombre visible del dispositivo en la lista: el que la app mandó al
/// registrarse (desde la app nueva, el modelo real del equipo: "OnePlus
/// CPH2749"). Si vino nulo o vacío —sesiones viejas o un cliente que no lo
/// manda— cae a la plataforma. No se inventa nada: lo que no vino, no se
/// muestra.
///
/// Cuando el backend despliegue `display_name`/`model`, se le da prioridad acá
/// y el resto de la pantalla no cambia.
String deviceNameLabel(String? name, String? platform) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? platformLabel(platform) : trimmed;
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
