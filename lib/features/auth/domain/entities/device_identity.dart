/// Datos del equipo (no del usuario) que la app conoce de sí misma y manda al
/// registrar el dispositivo en el login.
///
/// Hoy solo se usa [model] para armar `device.name`, que es lo único que el
/// backend desplegado acepta. Cuando el backend sume `X-Device-Model` /
/// `X-Device-Os-Version` y el cliente API se regenere, estos mismos campos van
/// derecho a esas cabeceras: no hay que volver a averiguar nada.
class DeviceIdentity {
  const DeviceIdentity({this.model, this.osVersion});

  /// Equipo desconocido: tests, web, o no se pudo leer nada del sistema.
  static const unknown = DeviceIdentity();

  /// Modelo comercial del equipo, listo para mostrar al usuario:
  /// "OnePlus CPH2749", "Honor Magic5 Lite". `null` si no se pudo averiguar.
  final String? model;

  /// Versión del sistema operativo, p. ej. "Android 14". `null` si no se pudo
  /// averiguar. Reservado para la cabecera `X-Device-Os-Version`; NO se usa
  /// para armar el nombre visible.
  final String? osVersion;

  /// Hay un modelo usable para mostrar/mandar.
  bool get hasModel => (model?.trim().isNotEmpty) ?? false;
}
