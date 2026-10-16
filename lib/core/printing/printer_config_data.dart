import 'dart:convert';

import 'printer_transport.dart';

/// Puerto TCP por defecto de las Zebra (raw/JetDirect) cuando no se indica otro.
const int kDefaultWifiPort = 9100;

/// Una impresora elegida y persistida.
///
/// [address] depende del transporte:
/// - bluetooth: el `remoteId` del dispositivo emparejado.
/// - wifi: `ip:puerto` (si falta el puerto se asume [kDefaultWifiPort]).
/// - usb: `vid:pid` del device (estable entre reconexiones, a diferencia del
///   deviceId que cambia al desenchufar).
class PrinterConfig {
  const PrinterConfig({
    required this.transport,
    required this.address,
    required this.label,
  });

  final PrinterTransport transport;
  final String address;

  /// Nombre legible para mostrar (p.ej. el modelo o el alias de red).
  final String label;

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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'transport': transport.name,
    'address': address,
    'label': label,
  };

  static PrinterConfig fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      transport: PrinterTransport.fromName(json['transport'] as String? ?? ''),
      address: json['address'] as String? ?? '',
      label: json['label'] as String? ?? '',
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
      other.label == label;

  @override
  int get hashCode => Object.hash(transport, address, label);
}
