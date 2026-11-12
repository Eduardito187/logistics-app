/// Protocolo de red con el que se le entrega el trabajo a una impresora WiFi.
///
/// - [raw9100]: socket TCP crudo (JetDirect, puerto 9100). No confirma nada:
///   la impresora acepta los bytes aunque después los descarte.
/// - [ipp]: Internet Printing Protocol (HTTP en 631). Responde si ACEPTÓ el
///   trabajo (con número), y permite autenticación por usuario/contraseña.
enum PrinterProtocol {
  raw9100,
  ipp;

  /// Desconocido o vacío → [raw9100] (compatibilidad con configs viejas).
  static PrinterProtocol fromName(String? name) => PrinterProtocol.values
      .firstWhere((p) => p.name == name, orElse: () => PrinterProtocol.raw9100);
}
