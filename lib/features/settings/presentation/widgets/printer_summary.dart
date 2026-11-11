import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';

/// Línea corta de la impresora, sin jerga: "Zebra · WiFi · 192.168.2.50",
/// "Oficina · WiFi · 192.168.2.154", "Zebra · Bluetooth", "Zebra · Cable USB".
/// El puerto solo se muestra si no es el habitual.
String printerSummary(PrinterConfig printer) {
  final kind = printer.isOffice ? 'Oficina' : 'Zebra';
  return switch (printer.transport) {
    PrinterTransport.bluetooth => '$kind · Bluetooth',
    PrinterTransport.usb => '$kind · Cable USB',
    PrinterTransport.wifi =>
      printer.wifiPort == kDefaultWifiPort
          ? '$kind · WiFi · ${printer.wifiHost}'
          : '$kind · WiFi · ${printer.address}',
  };
}

/// Ícono del transporte de la impresora.
AppIcon printerTransportIcon(PrinterTransport transport) =>
    switch (transport) {
      PrinterTransport.bluetooth => AppIcon.bluetooth,
      PrinterTransport.wifi => AppIcon.wifi,
      PrinterTransport.usb => AppIcon.usb,
    };
