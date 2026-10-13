import 'package:flutter/material.dart';

/// Roles de la app interna. La vista de inicio y los flujos disponibles dependen del rol.
enum UserRole {
  driver(
    label: 'Chofer',
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
    icon: Icons.qr_code_scanner,
    tasks: [
      'Escanear EAN e imprimir la etiqueta',
      'Asignar carril y posición de carga',
      'Carga validada del camión',
    ],
  ),
  store(
    label: 'Tienda',
    icon: Icons.storefront,
    tasks: [
      'Recepción contra manifiesto',
      'Ubicación en estante',
      'Entrega en mostrador (recojo)',
    ],
  ),
  carrier(
    label: 'Transportista externo',
    icon: Icons.handshake,
    tasks: ['Escanear al recoger', 'Escanear al entregar'],
  ),
  supervisor(
    label: 'Supervisor',
    icon: Icons.supervisor_account,
    tasks: ['Rutas en curso y alertas', 'Incidencias en campo'],
  );

  const UserRole({
    required this.label,
    required this.icon,
    required this.tasks,
  });

  final String label;
  final IconData icon;

  /// Flujos que este rol tendrá en la app (Fase 1). Se muestran en su pantalla de inicio.
  final List<String> tasks;
}
