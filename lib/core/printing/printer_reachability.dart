/// Resultado de "Probar conexión" a una impresora de red.
enum PrinterReachability {
  /// Aceptó la conexión TCP.
  reachable,

  /// Hay un equipo en esa IP pero rechazó el puerto (ECONNREFUSED).
  refused,

  /// No respondió en el tiempo de espera.
  timeout,

  /// No hay ruta desde la red del teléfono hasta esa IP.
  noRoute,

  /// IP/host o puerto inválidos (o el nombre no se pudo resolver).
  invalid,
}
