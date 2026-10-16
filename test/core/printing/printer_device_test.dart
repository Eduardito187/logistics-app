import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/printer_config.dart';

// PrinterDevice es el descubrimiento sin persistir; toConfig lo vuelve
// persistible usando el nombre como label.

void main() {
  group('PrinterDevice.toConfig', () {
    test('mapea transport, address y usa el name como label', () {
      const device = PrinterDevice(
        transport: PrinterTransport.usb,
        address: '1234:5678',
        name: 'Zebra ZQ630',
      );

      final config = device.toConfig();

      expect(config.transport, PrinterTransport.usb);
      expect(config.address, '1234:5678');
      expect(config.label, 'Zebra ZQ630');
      expect(
        config,
        const PrinterConfig(
          transport: PrinterTransport.usb,
          address: '1234:5678',
          label: 'Zebra ZQ630',
        ),
      );
    });

    test('conserva un name vacío como label vacío', () {
      const device = PrinterDevice(
        transport: PrinterTransport.bluetooth,
        address: 'AA:BB',
        name: '',
      );
      expect(device.toConfig().label, '');
    });
  });
}
