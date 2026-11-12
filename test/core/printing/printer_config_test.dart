import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/printer_config.dart';

// PrinterConfig: el `address` cambia de significado según el transporte
// (remoteId BT, ip:puerto WiFi, vid:pid USB). Se prueban los getters derivados,
// (de)serialización, decode defensivo e igualdad.

void main() {
  group('PrinterConfig — WiFi (ip:puerto)', () {
    test('separa host y puerto de "ip:puerto"', () {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.1.50:9100',
        label: 'Anden',
      );
      expect(config.wifiHost, '192.168.1.50');
      expect(config.wifiPort, 9100);
    });

    test('usa el puerto por defecto cuando falta el puerto', () {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.1.50',
        label: 'Anden',
      );
      expect(config.wifiHost, '192.168.1.50');
      expect(config.wifiPort, kDefaultWifiPort);
      expect(kDefaultWifiPort, 9100);
    });

    test('usa el puerto por defecto si el puerto no es numérico', () {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.1.50:abc',
        label: 'Anden',
      );
      expect(config.wifiPort, kDefaultWifiPort);
    });

    test('usa el puerto por defecto si el puerto viene vacío tras ":"', () {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.1.50:',
        label: 'Anden',
      );
      expect(config.wifiHost, '192.168.1.50');
      expect(config.wifiPort, kDefaultWifiPort);
    });

    test('host vacío cuando el address está vacío', () {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '',
        label: '',
      );
      expect(config.wifiHost, '');
      expect(config.wifiPort, kDefaultWifiPort);
    });
  });

  group('PrinterConfig — USB (vid:pid)', () {
    test('separa vendorId y productId de "vid:pid"', () {
      const config = PrinterConfig(
        transport: PrinterTransport.usb,
        address: '1234:5678',
        label: 'Cable',
      );
      expect(config.usbVendorId, 1234);
      expect(config.usbProductId, 5678);
    });

    test('productId null cuando falta la parte posterior', () {
      const config = PrinterConfig(
        transport: PrinterTransport.usb,
        address: '1234',
        label: 'Cable',
      );
      expect(config.usbVendorId, 1234);
      expect(config.usbProductId, isNull);
    });

    test('ambos null cuando el vid/pid no son numéricos', () {
      const config = PrinterConfig(
        transport: PrinterTransport.usb,
        address: 'zebra:printer',
        label: 'Cable',
      );
      expect(config.usbVendorId, isNull);
      expect(config.usbProductId, isNull);
    });
  });

  group('PrinterConfig — (de)serialización', () {
    test('toJson contiene transport, address, label y el perfil', () {
      const config = PrinterConfig(
        transport: PrinterTransport.bluetooth,
        address: 'AA:BB:CC',
        label: 'ZQ630',
      );
      expect(config.toJson(), <String, dynamic>{
        'transport': 'bluetooth',
        'address': 'AA:BB:CC',
        'label': 'ZQ630',
        'language': 'zpl',
        'protocol': 'raw9100',
      });
    });

    test('fromJson reconstruye el transporte por su name', () {
      final config = PrinterConfig.fromJson(<String, dynamic>{
        'transport': 'wifi',
        'address': '10.0.0.1:9100',
        'label': 'Red',
      });
      expect(config.transport, PrinterTransport.wifi);
      expect(config.address, '10.0.0.1:9100');
      expect(config.label, 'Red');
    });

    test('fromJson usa valores por defecto ante campos ausentes', () {
      final config = PrinterConfig.fromJson(const <String, dynamic>{});
      // transport desconocido -> bluetooth (fromName), strings -> vacíos.
      expect(config.transport, PrinterTransport.bluetooth);
      expect(config.address, '');
      expect(config.label, '');
    });

    test('encode/decode es una ida y vuelta', () {
      const config = PrinterConfig(
        transport: PrinterTransport.usb,
        address: '1234:5678',
        label: 'Cable',
      );
      expect(PrinterConfig.decode(config.encode()), config);
    });
  });

  group('PrinterConfig.decode — defensivo', () {
    test('null -> null', () {
      expect(PrinterConfig.decode(null), isNull);
    });

    test('string vacío -> null', () {
      expect(PrinterConfig.decode(''), isNull);
    });

    test('JSON corrupto -> null', () {
      expect(PrinterConfig.decode('{no-json'), isNull);
    });

    test('JSON que no es objeto -> null', () {
      expect(PrinterConfig.decode('[1,2]'), isNull);
    });

    test('objeto JSON válido -> config', () {
      final raw = jsonEncode(<String, dynamic>{
        'transport': 'bluetooth',
        'address': 'AA:BB',
        'label': 'X',
      });
      expect(PrinterConfig.decode(raw), isNotNull);
    });
  });

  group('PrinterConfig — igualdad', () {
    test('dos configs con mismos campos son iguales', () {
      const a = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '1.1.1.1:9100',
        label: 'L',
      );
      const b = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '1.1.1.1:9100',
        label: 'L',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('difieren si cambia transporte, address o label', () {
      const base = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '1.1.1.1:9100',
        label: 'L',
      );
      expect(
        base ==
            const PrinterConfig(
              transport: PrinterTransport.usb,
              address: '1.1.1.1:9100',
              label: 'L',
            ),
        isFalse,
      );
      expect(
        base ==
            const PrinterConfig(
              transport: PrinterTransport.wifi,
              address: '2.2.2.2:9100',
              label: 'L',
            ),
        isFalse,
      );
      expect(
        base ==
            const PrinterConfig(
              transport: PrinterTransport.wifi,
              address: '1.1.1.1:9100',
              label: 'OTRO',
            ),
        isFalse,
      );
    });

    test('no es igual a un objeto de otro tipo', () {
      const base = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '1.1.1.1',
        label: 'L',
      );
      expect(base == Object(), isFalse);
    });
  });

  group('PrinterConfig — perfil de impresión (zpl/office, raw9100/ipp)', () {
    test('JSON viejo (sin perfil) se lee como Zebra ZPL por 9100', () {
      final old = PrinterConfig.decode(
        jsonEncode(<String, dynamic>{
          'transport': 'wifi',
          'address': '192.168.2.154:9100',
          'label': 'WiFi 192.168.2.154',
        }),
      )!;
      expect(old.language, PrinterLanguage.zpl);
      expect(old.protocol, PrinterProtocol.raw9100);
      expect(old.ippPath, isNull);
      expect(old.ippPort, isNull);
      expect(old.ippTls, isFalse);
      expect(old.isOffice, isFalse);
    });

    test('valores desconocidos caen en zpl/raw9100', () {
      final config = PrinterConfig.fromJson(const <String, dynamic>{
        'transport': 'wifi',
        'address': '1.1.1.1:9100',
        'label': 'X',
        'language': 'postscript',
        'protocol': 'lpd',
        'ippPort': 'no',
      });
      expect(config.language, PrinterLanguage.zpl);
      expect(config.protocol, PrinterProtocol.raw9100);
      expect(config.ippPort, isNull);
    });

    test('perfil de oficina IPP: ida y vuelta completa', () {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.2.154:9100',
        label: 'RICOH IM 550',
        language: PrinterLanguage.office,
        protocol: PrinterProtocol.ipp,
        ippPath: '/printer',
        ippPort: 443,
        ippTls: true,
      );
      final back = PrinterConfig.decode(config.encode());
      expect(back, config);
      expect(back!.isOffice, isTrue);
      expect(config.toJson()['ippTls'], isTrue);
    });

    test('difieren si cambia el perfil', () {
      const base = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '1.1.1.1:9100',
        label: 'L',
      );
      expect(base == base.copyWith(language: PrinterLanguage.office), isFalse);
      expect(base == base.copyWith(protocol: PrinterProtocol.ipp), isFalse);
      expect(base == base.copyWith(ippPath: '/ipp'), isFalse);
    });

    test('copyWith puede volver ippPath/ippPort a null', () {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '1.1.1.1:9100',
        label: 'L',
        ippPath: '/ipp',
        ippPort: 631,
      );
      final cleared = config.copyWith(ippPath: null, ippPort: null);
      expect(cleared.ippPath, isNull);
      expect(cleared.ippPort, isNull);
      expect(config.copyWith().ippPath, '/ipp');
    });
  });
}
