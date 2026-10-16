import 'printer_config_data.dart';
import 'printer_transport.dart';

/// Una impresora descubierta por [LabelPrinter.discover], aún no persistida.
class PrinterDevice {
  const PrinterDevice({
    required this.transport,
    required this.address,
    required this.name,
  });

  final PrinterTransport transport;
  final String address;
  final String name;

  /// Convierte el descubrimiento en una configuración persistible.
  PrinterConfig toConfig() =>
      PrinterConfig(transport: transport, address: address, label: name);
}
