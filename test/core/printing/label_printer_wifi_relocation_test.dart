import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/wifi_printer_hit.dart';
import 'package:logistics_app/core/printing/wifi_printer_scanner.dart';

import '../auth/test_fakes.dart';

// Re-localización WiFi de LabelPrinter: si la IP guardada no responde y la
// impresora tiene nombre identificado, se la busca por nombre en la red y se
// imprime en la nueva dirección. Sin hardware: la "Zebra" es un ServerSocket en
// loopback y la IP vieja es un puerto cerrado. El scanner es un doble que
// responde findByName sin barrer la red.

/// Scanner que no toca la red: findByName devuelve [hit] y registra la llamada.
class _FakeScanner extends WifiPrinterScanner {
  _FakeScanner(this.hit);

  final WifiPrinterHit? hit;
  final List<(String, int)> calls = [];

  @override
  Future<WifiPrinterHit?> findByName(
    String name, {
    int port = kDefaultWifiPort,
  }) async {
    calls.add((name, port));
    return hit;
  }
}

/// Impresora falsa: acepta conexiones y guarda los bytes recibidos.
class _FakeZebra {
  _FakeZebra._(this._server) {
    _server.listen((socket) {
      final buffer = <int>[];
      socket.listen(
        buffer.addAll,
        onDone: () {
          if (!_received.isCompleted) {
            _received.complete(utf8.decode(buffer));
          }
          socket.destroy();
        },
        onError: (Object _) => socket.destroy(),
      );
    });
  }

  static Future<_FakeZebra> start() async =>
      _FakeZebra._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));

  final ServerSocket _server;
  final Completer<String> _received = Completer<String>();

  int get port => _server.port;

  /// Primer ZPL recibido (espera a que el cliente cierre la conexión).
  Future<String> get received =>
      _received.future.timeout(const Duration(seconds: 10));

  bool get gotSomething => _received.isCompleted;

  Future<void> close() => _server.close();
}

/// Puerto de loopback sin nadie escuchando (se abre y se cierra).
Future<int> _closedPort() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();
  return port;
}

const _zpl = '^XA^FO20,20^FDhola^FS^XZ';
const _name = 'Zebra ZD421';

/// La Zebra falsa no contesta ~HS: espera corta para no frenar los tests.
const _quick = Duration(milliseconds: 200);

void main() {
  late FakeSecureStorage storage;
  late _FakeZebra zebra;
  late int deadPort;

  setUp(() async {
    storage = FakeSecureStorage();
    zebra = await _FakeZebra.start();
    deadPort = await _closedPort();
  });

  tearDown(() async {
    await zebra.close();
  });

  /// Impresora guardada en una "IP vieja" que ya no responde. Se usa el host
  /// `localhost` para que difiera del `127.0.0.1` de la nueva dirección.
  PrinterConfig oldConfig(String label) => PrinterConfig(
    transport: PrinterTransport.wifi,
    address: 'localhost:$deadPort',
    label: label,
  );

  WifiPrinterHit movedHit() =>
      WifiPrinterHit(host: '127.0.0.1', port: zebra.port, name: _name);

  group('LabelPrinter — re-localización WiFi', () {
    test(
      'IP vieja caída: imprime en la nueva y persiste la seleccionada',
      () async {
        final scanner = _FakeScanner(movedHit());
        final printer = LabelPrinter(
          storage,
          wifiScanner: scanner,
          zebraStatusTimeout: _quick,
        );
        await printer.selectPrinter(oldConfig(_name));

        await printer.printZpl(_zpl);

        // El ZPL va seguido de ~HS (consulta de estado de la Zebra).
        expect(await zebra.received, '$_zpl~HS');
        expect(scanner.calls.single, (_name, deadPort));
        expect(
          await printer.selectedPrinter(),
          PrinterConfig(
            transport: PrinterTransport.wifi,
            address: '127.0.0.1:${zebra.port}',
            label: _name,
          ),
        );
      },
    );

    test('con destino explícito (to:) imprime pero no persiste', () async {
      final scanner = _FakeScanner(movedHit());
      final printer = LabelPrinter(
        storage,
        wifiScanner: scanner,
        zebraStatusTimeout: _quick,
      );
      final old = oldConfig(_name);
      await printer.selectPrinter(old);

      await printer.printZpl(_zpl, to: old);

      // El ZPL va seguido de ~HS (consulta de estado de la Zebra).
      expect(await zebra.received, '$_zpl~HS');
      expect(await printer.selectedPrinter(), old);
    });

    test('label manual "WiFi <ip>" no se re-localiza', () async {
      final scanner = _FakeScanner(movedHit());
      final printer = LabelPrinter(
        storage,
        wifiScanner: scanner,
        zebraStatusTimeout: _quick,
      );

      await expectLater(
        printer.printZpl(_zpl, to: oldConfig('WiFi 1.2.3.4')),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            startsWith('No se pudo conectar a localhost:$deadPort'),
          ),
        ),
      );
      expect(scanner.calls, isEmpty);
      expect(zebra.gotSomething, isFalse);
    });

    test('findByName sin coincidencia -> PrinterException', () async {
      final scanner = _FakeScanner(null);
      final printer = LabelPrinter(
        storage,
        wifiScanner: scanner,
        zebraStatusTimeout: _quick,
      );
      final old = oldConfig(_name);
      await printer.selectPrinter(old);

      await expectLater(
        printer.printZpl(_zpl),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            startsWith('No se pudo conectar'),
          ),
        ),
      );
      expect(scanner.calls, hasLength(1));
      expect(await printer.selectedPrinter(), old);
    });

    test('la "nueva" IP es la misma host -> no reintenta', () async {
      final scanner = _FakeScanner(
        WifiPrinterHit(host: 'localhost', port: zebra.port, name: _name),
      );
      final printer = LabelPrinter(
        storage,
        wifiScanner: scanner,
        zebraStatusTimeout: _quick,
      );

      await expectLater(
        printer.printZpl(_zpl, to: oldConfig(_name)),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            startsWith('No se pudo conectar'),
          ),
        ),
      );
      expect(zebra.gotSomething, isFalse);
    });

    test('sin scanner no hay re-localización', () async {
      final printer = LabelPrinter(storage);

      await expectLater(
        printer.printZpl(_zpl, to: oldConfig(_name)),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            startsWith('No se pudo conectar'),
          ),
        ),
      );
    });

    test('la nueva dirección también falla -> error y no persiste', () async {
      final otherDead = await _closedPort();
      final scanner = _FakeScanner(
        WifiPrinterHit(host: '127.0.0.1', port: otherDead, name: _name),
      );
      final printer = LabelPrinter(
        storage,
        wifiScanner: scanner,
        zebraStatusTimeout: _quick,
      );
      final old = oldConfig(_name);
      await printer.selectPrinter(old);

      await expectLater(
        printer.printZpl(_zpl),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            startsWith('No se pudo imprimir por WiFi'),
          ),
        ),
      );
      expect(await printer.selectedPrinter(), old);
    });
  });
}
