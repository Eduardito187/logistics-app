import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/printer_transport.dart';

// Transporte físico de la impresora. fromName debe aceptar los `name` del enum
// y caer a bluetooth ante cualquier valor desconocido (compat hacia atrás con
// una config vieja o corrupta).

void main() {
  group('PrinterTransport.label', () {
    test('cada transporte tiene su etiqueta legible', () {
      expect(PrinterTransport.bluetooth.label, 'Bluetooth');
      expect(PrinterTransport.wifi.label, 'WiFi');
      expect(PrinterTransport.usb.label, 'USB');
    });

    test('hay exactamente tres transportes', () {
      expect(PrinterTransport.values, hasLength(3));
    });
  });

  group('PrinterTransport.fromName', () {
    test('resuelve el name de cada transporte', () {
      expect(
        PrinterTransport.fromName('bluetooth'),
        PrinterTransport.bluetooth,
      );
      expect(PrinterTransport.fromName('wifi'), PrinterTransport.wifi);
      expect(PrinterTransport.fromName('usb'), PrinterTransport.usb);
    });

    test('cae a bluetooth ante un name desconocido', () {
      expect(PrinterTransport.fromName('zigbee'), PrinterTransport.bluetooth);
    });

    test('cae a bluetooth ante un string vacío', () {
      expect(PrinterTransport.fromName(''), PrinterTransport.bluetooth);
    });

    test('es sensible a mayúsculas (usa el name crudo del enum)', () {
      // 'WiFi' es la etiqueta, no el name ('wifi'): no debe resolver a wifi.
      expect(PrinterTransport.fromName('WiFi'), PrinterTransport.bluetooth);
    });

    test('es una ida y vuelta con name para cada valor', () {
      for (final transport in PrinterTransport.values) {
        expect(PrinterTransport.fromName(transport.name), transport);
      }
    });
  });
}
