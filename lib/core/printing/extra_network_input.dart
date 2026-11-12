import 'ipv4.dart';
import 'ipv4_subnet.dart';
import 'local_network.dart';

/// Interpreta la red extra que escribe el usuario para buscar impresoras fuera
/// de la red del teléfono (p. ej. la red de cable de la oficina).
///
/// Acepta `192.168.2` (→ /24), `192.168.2.0/24`, `10.20.0.0/22` o una IP
/// completa (`192.168.2.154` → su /24). Tope /22 (1022 direcciones).
abstract final class ExtraNetworkInput {
  static const String emptyError = 'Escribí la red. Ej. 192.168.2';
  static const String formatError =
      'Red inválida. Ej. 192.168.2 o 192.168.2.0/24';
  static const String tooBigError =
      'Red muy grande: el máximo es /22 (1022 direcciones).';
  static const String publicError =
      'Solo redes privadas (10.x, 172.16–31.x o 192.168.x).';

  /// `(subred, null)` si es válida; `(null, mensaje)` si no.
  static (Ipv4Subnet?, String?) parse(String raw) {
    final text = raw.trim().replaceAll(' ', '');
    if (text.isEmpty) return (null, emptyError);
    final parts = text.split('/');
    if (parts.length > 2) return (null, formatError);

    var address = parts.first;
    if (address.endsWith('.')) {
      address = address.substring(0, address.length - 1);
    }
    final octets = address.split('.');
    if (octets.length == 3) {
      address = '$address.0';
    } else if (octets.length != 4) {
      return (null, formatError);
    }
    final ip = Ipv4.parse(address);
    if (ip == null) return (null, formatError);

    var prefix = 24;
    if (parts.length == 2) {
      final parsed = int.tryParse(parts[1]);
      if (parsed == null || parsed < 0 || parsed > 32) {
        return (null, formatError);
      }
      prefix = parsed;
    }
    if (prefix < kMinScanPrefixLength) return (null, tooBigError);
    if (!Ipv4.isPrivate(ip)) return (null, publicError);
    return (Ipv4Subnet.containing(ip, prefix), null);
  }
}
