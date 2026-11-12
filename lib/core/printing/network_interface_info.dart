/// Interfaz de red IPv4 del teléfono: nombre, IP y largo del prefijo (máscara).
///
/// Viene del canal nativo `bo.com.dismac/network` (máscara real) o, si no
/// está, de `dart:io` asumiendo /24.
class NetworkInterfaceInfo {
  const NetworkInterfaceInfo({
    required this.name,
    required this.ip,
    this.prefixLength = 24,
  });

  /// Nombre del sistema (`wlan0`, `eth0`, `Wi-Fi`).
  final String name;
  final String ip;

  /// Bits de la máscara (24 = 255.255.255.0, 22 = 255.255.252.0).
  final int prefixLength;

  @override
  bool operator ==(Object other) =>
      other is NetworkInterfaceInfo &&
      other.name == name &&
      other.ip == ip &&
      other.prefixLength == prefixLength;

  @override
  int get hashCode => Object.hash(name, ip, prefixLength);

  @override
  String toString() => '$name $ip/$prefixLength';
}
