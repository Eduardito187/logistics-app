import 'ipv4.dart';

/// Subred IPv4 (`dirección de red / prefijo`), p. ej. `10.168.48.0/22`.
class Ipv4Subnet {
  const Ipv4Subnet._(this.network, this.prefixLength);

  /// Subred de prefijo [prefixLength] (0–32) que contiene a [ip].
  factory Ipv4Subnet.containing(int ip, int prefixLength) {
    final prefix = prefixLength.clamp(0, 32);
    return Ipv4Subnet._(ip & _maskFor(prefix), prefix);
  }

  /// Dirección de red (entero de 32 bits).
  final int network;
  final int prefixLength;

  static int _maskFor(int prefix) =>
      prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;

  int get mask => _maskFor(prefixLength);

  /// Dirección de broadcast (última de la subred).
  int get broadcast => network | (~mask & 0xFFFFFFFF);

  /// Texto para la UI y para persistir: `192.168.2.0/24`.
  String get label => '${Ipv4.format(network)}/$prefixLength';

  bool contains(int ip) => (ip & mask) == network;

  /// Cantidad de hosts barribles (sin red ni broadcast; /31 y /32 completas).
  int get hostCount {
    if (prefixLength >= 31) return 1 << (32 - prefixLength);
    return (1 << (32 - prefixLength)) - 2;
  }

  /// Direcciones de host, en orden (sin red ni broadcast).
  Iterable<int> get hosts sync* {
    if (prefixLength >= 31) {
      for (var ip = network; ip <= broadcast; ip++) {
        yield ip;
      }
      return;
    }
    for (var ip = network + 1; ip < broadcast; ip++) {
      yield ip;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Ipv4Subnet &&
      other.network == network &&
      other.prefixLength == prefixLength;

  @override
  int get hashCode => Object.hash(network, prefixLength);

  @override
  String toString() => label;
}
