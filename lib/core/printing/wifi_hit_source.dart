/// Cómo se encontró una impresora de red (solo para diagnóstico).
enum WifiHitSource {
  /// Barrido de la red del teléfono.
  sweep,

  /// Barrido de una red agregada por el usuario.
  addedNetwork,

  /// Anunciada por mDNS/Bonjour.
  mdns,

  /// Respondió a WS-Discovery.
  wsd,
}
