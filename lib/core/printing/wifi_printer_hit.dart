import 'printer_config_data.dart';
import 'printer_transport.dart';
import 'wifi_hit_source.dart';

/// Impresora encontrada en la red local por la búsqueda automática.
class WifiPrinterHit {
  const WifiPrinterHit({
    required this.host,
    required this.port,
    this.name,
    this.isZebra = false,
    this.source = WifiHitSource.sweep,
  });

  final String host;
  final int port;

  /// Nombre/modelo (servicio mDNS o `<title>` de su web); `null` si no se pudo
  /// identificar.
  final String? name;
  final bool isZebra;

  /// Cómo se la encontró (solo diagnóstico).
  final WifiHitSource source;

  /// `ip:puerto`, el formato de [PrinterConfig.address] para WiFi.
  String get address => '$host:$port';

  /// Nombre para mostrar: el identificado o uno genérico.
  String get displayName => name ?? 'Impresora de red';

  /// `true` si se identificó y NO es Zebra (Ricoh, HP…): imprimiría el ZPL
  /// como texto. Las sin identificar no cuentan (no se sabe).
  bool get isKnownNonZebra => name != null && !isZebra;

  /// Configuración persistible. Con nombre identificado se guarda ese nombre:
  /// sirve para volver a encontrarla si el router le cambia la IP. Sin nombre
  /// se usa `WiFi <ip>` (igual que el ingreso manual, sin re-localización).
  PrinterConfig toConfig() => PrinterConfig(
    transport: PrinterTransport.wifi,
    address: address,
    label: name ?? 'WiFi $host',
  );

  /// Une dos hallazgos de la misma `ip:puerto`: el nombre mDNS gana (es el
  /// de la impresora; el `<title>` web suele ser genérico, p. ej. "Web Image
  /// Monitor"); Zebra si cualquiera lo detectó; se conserva el primer origen.
  WifiPrinterHit merge(WifiPrinterHit other) => WifiPrinterHit(
    host: host,
    port: port,
    name: other.source == WifiHitSource.mdns && other.name != null
        ? other.name
        : (name ?? other.name),
    isZebra: isZebra || other.isZebra,
    source: source,
  );

  /// IP como número (para ordenar 192.168.1.9 antes que 192.168.1.10).
  int get _numericHost => host
      .split('.')
      .fold(0, (acc, part) => acc * 256 + (int.tryParse(part) ?? 0));

  /// Orden de la lista: primero Zebra, luego identificadas, luego por IP.
  static int compare(WifiPrinterHit a, WifiPrinterHit b) {
    if (a.isZebra != b.isZebra) return a.isZebra ? -1 : 1;
    if ((a.name == null) != (b.name == null)) return a.name != null ? -1 : 1;
    return a._numericHost.compareTo(b._numericHost);
  }
}
