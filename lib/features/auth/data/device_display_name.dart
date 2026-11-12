import '../domain/entities/device_identity.dart';

/// Nombre genérico de siempre. Se manda cuando no se pudo averiguar el modelo
/// del equipo: la pantalla "Mis dispositivos" mostrará esto (como antes), pero
/// el login nunca se rompe por no conocer el teléfono.
const String genericDeviceName = 'App interna';

/// Nombre que viaja en `device.name` al registrar el dispositivo y que el
/// usuario ve en "Mis dispositivos" para decidir cuál dar de baja.
///
/// Se usa el modelo real del equipo ("OnePlus CPH2749") en vez de una
/// constante: con el nombre fijo, un usuario con tres teléfonos veía tres filas
/// idénticas y no podía saber cuál revocar si perdía uno.
String deviceDisplayName(DeviceIdentity identity) =>
    identity.hasModel ? identity.model!.trim() : genericDeviceName;
