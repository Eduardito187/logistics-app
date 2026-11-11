import 'ipv4.dart';
import 'ipv4_subnet.dart';
import 'network_interface_info.dart';

/// Prefijo mínimo que se barre completo: /22 = 1022 hosts (~8–10 s). Una red
/// más grande (/16, /20) se barre solo en el bloque /22 de la IP del teléfono.
const int kMinScanPrefixLength = 22;

/// Red local (IPv4 privada) a la que está conectado el teléfono, sobre la que
/// se buscan impresoras WiFi.
///
/// La máscara real viene del canal nativo; sin él se asume /24 (la de casi
/// todo WiFi de local/andén).
class LocalNetwork {
  const LocalNetwork({
    required this.interfaceName,
    required this.ownIp,
    this.prefixLength = 24,
  });

  /// Nombre de la interfaz del sistema (p. ej. `wlan0`).
  final String interfaceName;

  /// IP del propio teléfono (se excluye del barrido).
  final String ownIp;

  /// Largo real del prefijo de la red (máscara).
  final int prefixLength;

  int get _ownIpValue => Ipv4.parse(ownIp) ?? 0;

  /// Subred real del teléfono (p. ej. `10.168.0.0/16`).
  Ipv4Subnet get subnet => Ipv4Subnet.containing(_ownIpValue, prefixLength);

  /// Lo que se barre: la subred completa si es /22 o menor; si es más grande,
  /// el bloque /22 que contiene la IP del teléfono.
  Ipv4Subnet get scanSubnet => isScanLimited
      ? Ipv4Subnet.containing(_ownIpValue, kMinScanPrefixLength)
      : subnet;

  /// `true` si la red es más grande que lo que se barre (/16, /20…).
  bool get isScanLimited => prefixLength < kMinScanPrefixLength;

  /// Texto para la UI: la red barrida (`10.168.48.0/22`).
  String get label => scanSubnet.label;

  /// Interfaces que NO son WiFi/LAN: datos móviles, VPN, túneles. Un 10.x de
  /// datos móviles es "privado" pero no es la red del local.
  static const List<String> _excludedPrefixes = [
    'rmnet',
    'ccmni',
    'pdp',
    'wwan',
    'tun',
    'ppp',
    'clat',
    'v4-',
    'dummy',
    'ipsec',
    'utun',
  ];

  /// Redes candidatas a partir de las interfaces IPv4 del sistema. Solo IPs
  /// privadas (10/8, 172.16/12, 192.168/16) de interfaces WiFi/LAN; WiFi
  /// (`wlan*`) primero. Sin duplicados por rango barrido.
  static List<LocalNetwork> fromInterfaces(
    List<NetworkInterfaceInfo> interfaces,
  ) {
    final candidates = <LocalNetwork>[];
    for (final iface in interfaces) {
      final lower = iface.name.toLowerCase();
      // Loopback exacto (`lo`, `lo0`): no excluir por prefijo "lo" a secas.
      if (lower == 'lo' || lower == 'lo0') continue;
      if (_excludedPrefixes.any(lower.startsWith)) continue;
      final ip = Ipv4.parse(iface.ip);
      if (ip == null || !Ipv4.isPrivate(ip)) continue;
      // Máscara inválida (o /0–/7, que sería absurda en un local) → /24.
      final prefix = iface.prefixLength >= 8 && iface.prefixLength <= 32
          ? iface.prefixLength
          : 24;
      candidates.add(
        LocalNetwork(
          interfaceName: iface.name,
          ownIp: Ipv4.format(ip),
          prefixLength: prefix,
        ),
      );
    }
    // Ordenar ANTES de deduplicar: si wlan y eth comparten red, gana wlan.
    // `sort` de Dart no es estable: se desempata por posición original.
    final indexed = candidates.indexed.toList()
      ..sort((a, b) {
        final byRank = _rank(a.$2).compareTo(_rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    final seen = <Ipv4Subnet>{};
    return [
      for (final (_, n) in indexed)
        if (seen.add(n.scanSubnet)) n,
    ];
  }

  static int _rank(LocalNetwork n) {
    final name = n.interfaceName.toLowerCase();
    if (name.startsWith('wlan') || name.startsWith('wi-fi')) return 0;
    if (name.startsWith('eth') || name.startsWith('en')) return 1;
    return 2;
  }
}
