/// Utilidades de direcciones IPv4 como enteros de 32 bits (sin plugins).
abstract final class Ipv4 {
  /// `192.168.1.5` → entero, o `null` si no es una IPv4 de cuatro octetos.
  static int? parse(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 4) return null;
    var out = 0;
    for (final p in parts) {
      if (p.isEmpty || p.length > 3) return null;
      final v = int.tryParse(p);
      if (v == null || v < 0 || v > 255) return null;
      out = (out << 8) | v;
    }
    return out;
  }

  /// Entero → `a.b.c.d`.
  static String format(int ip) =>
      '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.'
      '${ip & 0xFF}';

  /// Rango privado (10/8, 172.16/12, 192.168/16): las redes de un local. Una
  /// IP pública no se barre nunca.
  static bool isPrivate(int ip) {
    final a = (ip >> 24) & 0xFF;
    final b = (ip >> 16) & 0xFF;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }
}
