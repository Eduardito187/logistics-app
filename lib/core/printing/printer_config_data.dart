import 'dart:convert';

import 'printer_language.dart';
import 'printer_protocol.dart';
import 'printer_transport.dart';

/// Puerto TCP por defecto de las Zebra (raw/JetDirect) cuando no se indica otro.
const int kDefaultWifiPort = 9100;

/// Puerto IPP estándar (HTTP en 631).
const int kDefaultIppPort = 631;

/// Ruta IPP por defecto (IPP Everywhere / Mopria).
const String kDefaultIppPath = '/ipp/print';

/// Centinela de [PrinterConfig.copyWith] para poder volver un campo a `null`.
const Object _unset = Object();

/// Una impresora elegida y persistida.
///
/// [address] depende del transporte:
/// - bluetooth: el `remoteId` del dispositivo emparejado.
/// - wifi: `ip:puerto` (si falta el puerto se asume [kDefaultWifiPort]).
/// - usb: `vid:pid` del device (estable entre reconexiones, a diferencia del
///   deviceId que cambia al desenchufar).
///
/// Perfil de impresión ([language], [protocol], [ippPath], [ippPort],
/// [ippTls]): qué se le manda y cómo. Las configs viejas (sin esos campos) se
/// leen como Zebra ZPL por 9100, que es lo único que la app hacía antes.
/// Las credenciales NO viven acá (ver `PrinterCredentialsStore`).
class PrinterConfig {
  const PrinterConfig({
    required this.transport,
    required this.address,
    required this.label,
    this.language = PrinterLanguage.zpl,
    this.protocol = PrinterProtocol.raw9100,
    this.ippPath,
    this.ippPort,
    this.ippTls = false,
  });

  final PrinterTransport transport;
  final String address;

  /// Nombre legible para mostrar (p.ej. el modelo o el alias de red).
  final String label;

  /// ZPL (Zebra) u oficina (PDF/PWG/PCL).
  final PrinterLanguage language;

  /// Cómo llega el trabajo a una impresora WiFi: 9100 crudo o IPP.
  final PrinterProtocol protocol;

  /// Ruta IPP detectada (`/ipp/print`, `/printer`…); `null` = probar las
  /// conocidas.
  final String? ippPath;

  /// Puerto IPP detectado; `null` = [kDefaultIppPort].
  final int? ippPort;

  /// `true` si la impresora solo respondió IPP por HTTPS (ipps).
  final bool ippTls;

  /// Host de una impresora WiFi (parte previa a `:`). Vacío si no aplica.
  String get wifiHost => address.split(':').first;

  /// Puerto de una impresora WiFi; [kDefaultWifiPort] si no viene en [address].
  int get wifiPort {
    final parts = address.split(':');
    if (parts.length < 2) return kDefaultWifiPort;
    return int.tryParse(parts[1]) ?? kDefaultWifiPort;
  }

  /// Vendor id de una impresora USB (parte previa a `:`), o null si no aplica.
  int? get usbVendorId => int.tryParse(address.split(':').first);

  /// Product id de una impresora USB (parte posterior a `:`), o null.
  int? get usbProductId {
    final parts = address.split(':');
    if (parts.length < 2) return null;
    return int.tryParse(parts[1]);
  }

  /// `true` si es una impresora de oficina (no entiende ZPL).
  bool get isOffice => language == PrinterLanguage.office;

  PrinterConfig copyWith({
    PrinterTransport? transport,
    String? address,
    String? label,
    PrinterLanguage? language,
    PrinterProtocol? protocol,
    Object? ippPath = _unset,
    Object? ippPort = _unset,
    bool? ippTls,
  }) {
    return PrinterConfig(
      transport: transport ?? this.transport,
      address: address ?? this.address,
      label: label ?? this.label,
      language: language ?? this.language,
      protocol: protocol ?? this.protocol,
      ippPath: identical(ippPath, _unset) ? this.ippPath : ippPath as String?,
      ippPort: identical(ippPort, _unset) ? this.ippPort : ippPort as int?,
      ippTls: ippTls ?? this.ippTls,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'transport': transport.name,
    'address': address,
    'label': label,
    'language': language.name,
    'protocol': protocol.name,
    if (ippPath != null) 'ippPath': ippPath,
    if (ippPort != null) 'ippPort': ippPort,
    if (ippTls) 'ippTls': true,
  };

  static PrinterConfig fromJson(Map<String, dynamic> json) {
    final port = json['ippPort'];
    final path = json['ippPath'];
    return PrinterConfig(
      transport: PrinterTransport.fromName(json['transport'] as String? ?? ''),
      address: json['address'] as String? ?? '',
      label: json['label'] as String? ?? '',
      // Configs viejas: sin estos campos = Zebra ZPL por 9100.
      language: PrinterLanguage.fromName(json['language'] as String?),
      protocol: PrinterProtocol.fromName(json['protocol'] as String?),
      ippPath: path is String && path.isNotEmpty ? path : null,
      ippPort: port is int ? port : null,
      ippTls: json['ippTls'] == true,
    );
  }

  String encode() => jsonEncode(toJson());

  static PrinterConfig? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return PrinterConfig.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PrinterConfig &&
      other.transport == transport &&
      other.address == address &&
      other.label == label &&
      other.language == language &&
      other.protocol == protocol &&
      other.ippPath == ippPath &&
      other.ippPort == ippPort &&
      other.ippTls == ippTls;

  @override
  int get hashCode => Object.hash(
    transport,
    address,
    label,
    language,
    protocol,
    ippPath,
    ippPort,
    ippTls,
  );
}
