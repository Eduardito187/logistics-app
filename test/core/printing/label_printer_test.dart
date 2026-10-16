import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';

// LabelPrinter: selección/persistencia de impresora y validación de los
// errores de impresión POR TRANSPORTE que se detectan ANTES de tocar el
// hardware (sin impresora, WiFi sin IP, USB sin vid/pid). La E/S real por
// Bluetooth/WiFi/USB no es unit-testeable sin mockear los plugins; aquí se
// cubre la degradación segura (discover sin plugin -> lista vacía) y el
// wrapping de errores a PrinterException.

/// FlutterSecureStorage en memoria (solo read/write por clave).
class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> store = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) {
      final key = invocation.namedArguments[#key] as String;
      return Future<String?>.value(store[key]);
    }
    if (invocation.memberName == #write) {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String?;
      if (value == null) {
        store.remove(key);
      } else {
        store[key] = value;
      }
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSecureStorage storage;
  late LabelPrinter printer;

  setUp(() {
    storage = _FakeSecureStorage();
    printer = LabelPrinter(storage);
  });

  group('LabelPrinter — selección persistida', () {
    test('selectedPrinter es null cuando no hay nada guardado', () async {
      expect(await printer.selectedPrinter(), isNull);
    });

    test('selectPrinter persiste y selectedPrinter lo recupera', () async {
      const config = PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.1.5:9100',
        label: 'Anden',
      );

      await printer.selectPrinter(config);

      expect(await printer.selectedPrinter(), config);
    });
  });

  group('LabelPrinter.printZpl — errores previos al hardware', () {
    test('sin impresora seleccionada ni destino explícito', () async {
      await expectLater(
        printer.printZpl('^XA^XZ'),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            'No hay impresora seleccionada.',
          ),
        ),
      );
    });

    test('WiFi sin IP configurada', () async {
      await expectLater(
        printer.printZpl(
          '^XA^XZ',
          to: const PrinterConfig(
            transport: PrinterTransport.wifi,
            address: '',
            label: 'Red',
          ),
        ),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            contains('WiFi no tiene IP'),
          ),
        ),
      );
    });

    test('USB sin vid/pid identificado', () async {
      await expectLater(
        printer.printZpl(
          '^XA^XZ',
          to: const PrinterConfig(
            transport: PrinterTransport.usb,
            address: '',
            label: 'Cable',
          ),
        ),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            contains('USB no está identificada'),
          ),
        ),
      );
    });
  });

  group('LabelPrinter.discover', () {
    test('WiFi no tiene descubrimiento: lista vacía', () async {
      expect(await printer.discover(PrinterTransport.wifi), isEmpty);
    });

    test('Bluetooth degrada a lista vacía sin plugin disponible', () async {
      // El plugin no está montado en el entorno de test: la llamada lanza una
      // Exception que _bondedBluetooth atrapa y devuelve lista vacía.
      expect(await printer.discover(PrinterTransport.bluetooth), isEmpty);
    });

    test('USB degrada a lista vacía sin plugin disponible', () async {
      expect(await printer.discover(PrinterTransport.usb), isEmpty);
    });
  });

  group('LabelPrinter.printZpl — transporte sin hardware real', () {
    test('Bluetooth envuelve la falla del plugin en PrinterException', () async {
      // Con una impresora BT seleccionada pero sin stack BLE real, la conexión
      // falla y el error se reporta como PrinterException (mensaje en español),
      // nunca como una excepción cruda del plugin.
      await expectLater(
        printer.printZpl(
          '^XA^XZ',
          to: const PrinterConfig(
            transport: PrinterTransport.bluetooth,
            address: 'AA:BB:CC:DD:EE:FF',
            label: 'ZQ630',
          ),
        ),
        throwsA(isA<PrinterException>()),
      );
    });
  });
}
