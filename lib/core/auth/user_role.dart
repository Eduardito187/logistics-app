import '../icons/icons.dart';

/// Roles de la app interna. La vista de inicio y los flujos disponibles dependen del rol.
enum UserRole {
  driver(
    label: 'Chofer',
    backendKey: 'chofer',
    icon: AppIcon.deliver,
    tasks: [
      'Checklist pre-salida del camión',
      'Ruta del día y navegación con un toque',
      'Descarga guiada por parada',
      'Entrega con QR del cliente y foto',
      'Entregas fallidas con motivo y foto',
    ],
  ),
  picker(
    label: 'Preparador / andén',
    backendKey: 'preparador',
    icon: AppIcon.scan,
    tasks: [
      'Escanear EAN e imprimir la etiqueta',
      'Asignar carril y posición de carga',
      'Carga validada del camión',
    ],
  ),
  store(
    label: 'Tienda',
    backendKey: 'tienda',
    icon: AppIcon.pickupStore,
    tasks: [
      'Recepción contra manifiesto',
      'Ubicación en estante',
      'Recojo en tienda',
    ],
  ),
  carrier(
    label: 'Transportista externo',
    backendKey: 'transportista',
    icon: AppIcon.handshake,
    tasks: ['Escanear al recoger', 'Escanear al entregar'],
  ),
  supervisor(
    label: 'Supervisor',
    backendKey: 'supervisor',
    icon: AppIcon.supervisor,
    tasks: ['Rutas en curso y alertas', 'Incidencias en campo'],
  );

  const UserRole({
    required this.label,
    required this.backendKey,
    required this.icon,
    required this.tasks,
  });

  final String label;

  /// Clave del rol tal como la devuelve el backend (`App\Enums\Role`).
  final String backendKey;

  /// Ícono animado DisTrack del rol.
  final AppIcon icon;

  /// Flujos que este rol tendrá en la app (Fase 1). Se muestran en su pantalla de inicio.
  final List<String> tasks;

  /// ¿Este rol usa la impresora Zebra de etiquetas? Solo el preparador (imprime
  /// al escanear) y el supervisor (reimpresiones); al resto no se le muestra.
  bool get usesLabelPrinter =>
      this == UserRole.picker || this == UserRole.supervisor;

  /// Mapea una clave de rol del backend al rol de la app, o `null` si no es un
  /// rol operativo de terreno (p. ej. `admin`).
  static UserRole? fromBackendKey(String key) {
    for (final role in values) {
      if (role.backendKey == key) return role;
    }
    return null;
  }

  /// Elige el primer rol operativo de la lista de roles del usuario.
  static UserRole? firstOperational(Iterable<String> roleKeys) {
    for (final key in roleKeys) {
      final role = fromBackendKey(key);
      if (role != null) return role;
    }
    return null;
  }
}
