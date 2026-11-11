import 'network_printer_identity.dart';

/// Servicio anunciado por mDNS/Bonjour (como lo ve Windows): impresoras que
/// publican `_pdl-datastream._tcp` (9100), `_printer._tcp` (LPD) o
/// `_ipp._tcp`.
class MdnsService {
  const MdnsService({
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    this.txt = const {},
  });

  /// Nombre del servicio (`RICOH IM 550 [A1B2C3]`, `ZD421-203dpi ZPL`).
  final String name;
  final String type;

  /// IP (o host) resuelta por el sistema.
  final String host;
  final int port;

  /// Registros TXT (`product`, `ty`, `usb_MDL`…).
  final Map<String, String> txt;

  /// Claves TXT que traen el modelo de la impresora.
  static const List<String> _modelKeys = [
    'product',
    'ty',
    'usb_MDL',
    'usb_MFG',
  ];

  /// `true` si el nombre o el modelo en TXT es de una Zebra.
  bool get looksLikeZebra {
    if (NetworkPrinterIdentity.looksLikeZebra(name)) return true;
    for (final key in _modelKeys) {
      final value = txt[key];
      if (value != null && NetworkPrinterIdentity.looksLikeZebra(value)) {
        return true;
      }
    }
    return false;
  }

  /// `true` si es el servicio de impresión cruda (el que usa el 9100).
  bool get isRawPrinting => type.contains('_pdl-datastream');

  /// Puerto a probar: el anunciado si es impresión cruda; si no, [rawPort].
  int portToProbe(int rawPort) =>
      isRawPrinting && port > 0 && port <= 65535 ? port : rawPort;

  /// Desde el mapa del canal nativo; `null` si falta el host o el nombre.
  static MdnsService? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final host = raw['host'];
    if (name is! String || host is! String) return null;
    if (name.trim().isEmpty || host.trim().isEmpty) return null;
    final type = raw['type'];
    final port = raw['port'];
    final txtRaw = raw['txt'];
    return MdnsService(
      name: name.trim(),
      type: type is String ? type : '',
      host: host.trim(),
      port: port is int ? port : 0,
      txt: {
        if (txtRaw is Map)
          for (final e in txtRaw.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
      },
    );
  }
}
