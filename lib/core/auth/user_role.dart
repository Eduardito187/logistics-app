import 'package:flutter/material.dart';

/// Roles de la app interna. La vista de inicio y los flujos disponibles dependen del rol.
enum UserRole {
  driver(
    label: 'Chofer',
    backendKey: 'chofer',
    icon: Icons.local_shipping,
    tasks: [
      'Checklist pre-salida del camión',
      'Ruta del día y navegación con un toque',
      'Descarga guiada por parada',
      'Prueba de entrega con QR del cliente y foto',
      'Entregas fallidas con motivo y foto',
    ],
  ),
  picker(
    label: 'Preparador / andén',
    backendKey: 'preparador',
    icon: Icons.qr_code_scanner,
    tasks: [
      'Escanear EAN e imprimir la etiqueta',
      'Asignar carril y posición de carga',
      'Carga validada del camión',
    ],
  ),
  store(
    label: 'Tienda',
    backendKey: 'tienda',
    icon: Icons.storefront,
    tasks: [
      'Recepción contra manifiesto',
      'Ubicación en estante',
      'Entrega en mostrador (recojo)',
    ],
  ),
  carrier(
    label: 'Transportista externo',
    backendKey: 'transportista',
    icon: Icons.handshake,
    tasks: ['Escanear al recoger', 'Escanear al entregar'],
  ),
  supervisor(
    label: 'Supervisor',
    backendKey: 'supervisor',
    icon: Icons.supervisor_account,
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

  final IconData icon;

  /// Flujos que este rol tendrá en la app (Fase 1). Se muestran en su pantalla de inicio.
  final List<String> tasks;

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
