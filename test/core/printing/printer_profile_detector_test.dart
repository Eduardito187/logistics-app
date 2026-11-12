import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipp/ipp_client.dart';
import 'package:logistics_app/core/printing/ipp/ipp_http_response.dart';
import 'package:logistics_app/core/printing/ipp/ipp_tags.dart';
import 'package:logistics_app/core/printing/network_printer_identity.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/printer_detection.dart';
import 'package:logistics_app/core/printing/printer_profile_detector.dart';

import 'ipp/ipp_test_bytes.dart';

// Auto-detección del tipo de impresora: SOLO IPP y web (nunca 9100).

IppClient _ipp(IppHttpResponse Function(Uri uri) reply) => IppClient(
  httpPorts: const [631],
  httpsPorts: const [],
  paths: const ['/ipp/print'],
  transport:
      (uri, body, {String? authorization, required Duration timeout}) async =>
          reply(uri),
);

IppHttpResponse _ok(Uint8List body) =>
    IppHttpResponse(statusCode: 200, body: body);

void main() {
  const config = PrinterConfig(
    transport: PrinterTransport.wifi,
    address: '192.168.2.154:9100',
    label: 'WiFi 192.168.2.154',
  );

  test('Ricoh con IPP Basic → oficina por IPP y pide credenciales', () async {
    final detector = PrinterProfileDetector(
      ipp: _ipp((_) => _ok(ricohAttributesResponse())),
      identify: (host, timeout) async => null,
    );

    final d = await detector.detect('192.168.2.154');

    expect(d.ippAvailable, isTrue);
    expect(d.makeAndModel, 'RICOH IM 550');
    expect(d.requiresCredentials, isTrue);
    expect(d.language, PrinterLanguage.office);
    expect(d.protocol, PrinterProtocol.ipp);
    expect(
      d.summary,
      'RICOH IM 550: impresora de oficina por IPP. Pide usuario y '
      'contraseña: completá el acceso.',
    );
    final applied = d.applyTo(config);
    expect(applied.language, PrinterLanguage.office);
    expect(applied.protocol, PrinterProtocol.ipp);
    expect(applied.ippPath, '/ipp/print');
    expect(applied.ippPort, 631);
    expect(applied.address, config.address);
  });

  test(
    'Ricoh con código de usuario (requesting-user-name) → 9100 + USERCODE',
    () async {
      // IPP de esta Ricoh solo admite requesting-user-name: el equipo cancela los
      // trabajos IPP. Se imprime por 9100 con el código (verificado con la IM 550).
      final detector = PrinterProfileDetector(
        ipp: _ipp((_) => _ok(ricohUserNameOnlyResponse())),
        identify: (host, timeout) async => null,
      );

      final d = await detector.detect('192.168.2.154');

      expect(d.makeAndModel, 'RICOH IM 550 PS3');
      expect(d.requiresCredentials, isFalse);
      expect(d.needsUserCode, isTrue);
      expect(d.language, PrinterLanguage.office);
      expect(d.protocol, PrinterProtocol.raw9100);
      expect(d.summary, contains('código de usuario'));
      final applied = d.applyTo(config);
      expect(applied.protocol, PrinterProtocol.raw9100);
      // Sin datos IPP en una config de 9100.
      expect(applied.ippPort, isNull);
    },
  );

  test('IPP responde 401 → oficina por IPP con credenciales', () async {
    final detector = PrinterProfileDetector(
      ipp: _ipp(
        (_) => IppHttpResponse(
          statusCode: 401,
          body: Uint8List(0),
          challenges: const ['Basic realm="RICOH"'],
        ),
      ),
      identify: (host, timeout) async =>
          const NetworkPrinterIdentity(name: 'RICOH IM 550', isZebra: false),
    );

    final d = await detector.detect('192.168.2.154');

    expect(d.requiresCredentials, isTrue);
    expect(d.language, PrinterLanguage.office);
    expect(d.protocol, PrinterProtocol.ipp);
    expect(d.makeAndModel, 'RICOH IM 550');
  });

  test('Zebra que habla IPP → ZPL por 9100', () async {
    final zebra = ippResponse(0, [
      printerGroup([
        rec(
          IppTag.textWithoutLanguage,
          'printer-make-and-model',
          ascii.encode('Zebra ZD421'),
        ),
      ]),
    ]);
    final detector = PrinterProfileDetector(
      ipp: _ipp((_) => _ok(zebra)),
      identify: (host, timeout) async => null,
    );

    final d = await detector.detect('10.0.0.9');

    expect(d.isZebra, isTrue);
    expect(d.language, PrinterLanguage.zpl);
    expect(d.protocol, PrinterProtocol.raw9100);
    final applied = d.applyTo(
      config.copyWith(
        language: PrinterLanguage.office,
        protocol: PrinterProtocol.ipp,
        ippPath: '/x',
      ),
    );
    expect(applied.ippPath, isNull);
  });

  test('sin IPP: la web dice Zebra → ZPL; otra marca → PCL por 9100', () async {
    IppClient noIpp() => _ipp((_) => throw const SocketException('cerrado'));

    final zebra = await PrinterProfileDetector(
      ipp: noIpp(),
      identify: (host, timeout) async =>
          const NetworkPrinterIdentity(name: 'Zebra ZT230', isZebra: true),
    ).detect('h');
    expect(zebra.language, PrinterLanguage.zpl);

    final hp = await PrinterProfileDetector(
      ipp: noIpp(),
      identify: (host, timeout) async =>
          const NetworkPrinterIdentity(name: 'HP LaserJet', isZebra: false),
    ).detect('h');
    expect(hp.language, PrinterLanguage.office);
    expect(hp.protocol, PrinterProtocol.raw9100);
    expect(hp.ippAvailable, isFalse);
  });

  test('nada responde → desconocida, no cambia la config', () async {
    final d = await PrinterProfileDetector(
      ipp: _ipp((_) => throw const SocketException('cerrado')),
      identify: (host, timeout) async => null,
    ).detect('h');

    expect(d.identified, isFalse);
    expect(d.applyTo(config), config);
    expect(d.summary, contains('No se pudo identificar'));
    expect(PrinterDetection.unknown.identified, isFalse);
  });
}
