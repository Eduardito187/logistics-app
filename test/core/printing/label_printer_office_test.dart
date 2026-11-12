import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipp/ipp_client.dart';
import 'package:logistics_app/core/printing/ipp/ipp_codec.dart';
import 'package:logistics_app/core/printing/ipp/ipp_http_response.dart';
import 'package:logistics_app/core/printing/ipp/ipp_operation.dart';
import 'package:logistics_app/core/printing/ipp/ipp_tags.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/office/office_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/printer_credentials.dart';
import 'package:logistics_app/core/printing/printer_credentials_store.dart';

import '../auth/test_fakes.dart';
import 'ipp/ipp_test_bytes.dart';

// LabelPrinter.printLabel: impresoras de oficina (IPP / PCL+PJL) y estado de
// la Zebra por 9100 (~HS). Sin hardware: transportes falsos y un ServerSocket
// en loopback que hace de Zebra.

const _office = PrinterConfig(
  transport: PrinterTransport.wifi,
  address: '192.168.2.154:9100',
  label: 'RICOH IM 550',
  language: PrinterLanguage.office,
  protocol: PrinterProtocol.ipp,
);

Future<LabelRaster> _render() async =>
    LabelRaster(width: 4, height: 4, dpi: 100, pixels: Uint8List(16));

/// Zebra falsa: guarda lo recibido y, si llega `~HS`, contesta [reply].
class _Zebra {
  _Zebra._(this._server, this.reply) {
    _server.listen((socket) {
      socket.listen((data) {
        received.addAll(data);
        final text = latin1.decode(received);
        if (reply != null && text.endsWith('~HS')) socket.write(reply);
      }, onDone: socket.destroy);
    });
  }

  static Future<_Zebra> start([String? reply]) async =>
      _Zebra._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0), reply);

  final ServerSocket _server;
  final String? reply;
  final List<int> received = [];

  PrinterConfig get config => PrinterConfig(
    transport: PrinterTransport.wifi,
    address: '127.0.0.1:${_server.port}',
    label: 'WiFi 127.0.0.1',
  );

  Future<void> close() => _server.close();
}

String _hs(String paperOut, String headUp) =>
    '\x02030,$paperOut,0,0245,000,0,0,0,000,0,0,0\x03\r\n'
    '\x02001,0,$headUp,0,1,2,6,0,00000000,1,000\x03\r\n'
    '\x021234,0\x03\r\n';

void main() {
  late FakeSecureStorage storage;

  setUp(() => storage = FakeSecureStorage());

  group('printLabel — sin impresora', () {
    test('lanza notSelected (se arregla en Ajustes)', () async {
      await expectLater(
        LabelPrinter(storage).printLabel(zpl: '^XA^XZ'),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.needsSetup,
            'needsSetup',
            isTrue,
          ),
        ),
      );
    });
  });

  group('printLabel — impresora de oficina', () {
    test('sin dibujo de la etiqueta → no se le manda ZPL', () async {
      var sent = false;
      final printer = LabelPrinter(
        storage,
        officePrinter: OfficePrinter(raw: (h, p, b) async => sent = true),
      );

      await expectLater(
        printer.printLabel(zpl: '^XA^XZ', to: _office),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            startsWith('Esta impresora no imprime etiquetas Zebra'),
          ),
        ),
      );
      expect(sent, isFalse);
    });

    test('printZpl (compatibilidad) también avisa en oficina', () async {
      await expectLater(
        LabelPrinter(storage).printZpl('^XA^XZ', to: _office),
        throwsA(isA<PrinterException>()),
      );
    });

    test('oficina por Bluetooth → pide WiFi', () async {
      await expectLater(
        LabelPrinter(storage).printLabel(
          zpl: '^XA^XZ',
          render: _render,
          to: _office.copyWith(transport: PrinterTransport.bluetooth),
        ),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            contains('por WiFi'),
          ),
        ),
      );
    });

    test(
      '9100: PDF directo con PJL del usuario de la sesión, sin confirmación',
      () async {
        final sent = <(String, int, Uint8List)>[];
        final printer = LabelPrinter(
          storage,
          officePrinter: OfficePrinter(
            raw: (host, port, bytes) async => sent.add((host, port, bytes)),
          ),
          currentUser: () => 'jperez@dismac.com.bo',
        );

        final outcome = await printer.printLabel(
          zpl: '^XA^XZ',
          render: _render,
          jobName: 'Etiqueta 1234',
          to: _office.copyWith(protocol: PrinterProtocol.raw9100),
        );

        expect(outcome, const PrintOutcome.sentUnconfirmed());
        final (host, port, bytes) = sent.single;
        expect((host, port), ('192.168.2.154', 9100));
        final text = latin1.decode(bytes);
        expect(text, contains('@PJL SET USERID="jperez"'));
        expect(text, contains('@PJL SET JOBNAME="Etiqueta 1234"'));
        // PDF directo: entra en lenguaje PDF y el cuerpo es un PDF, NO PCL.
        expect(text, contains('@PJL ENTER LANGUAGE=PDF'));
        expect(text, contains('%PDF-'));
        expect(text, isNot(contains('^XA')));
        expect(text, isNot(contains('ENTER LANGUAGE=PCL')));
      },
    );

    test(
      '9100: el código de usuario guardado va por PJL (PDF directo)',
      () async {
        await PrinterCredentialsStore(storage).write(
          _office.address,
          const PrinterCredentials(username: 'ana', userCode: '4321'),
        );
        final sent = <Uint8List>[];
        final printer = LabelPrinter(
          storage,
          officePrinter: OfficePrinter(raw: (h, p, b) async => sent.add(b)),
        );

        await printer.printLabel(
          zpl: '',
          render: _render,
          to: _office.copyWith(protocol: PrinterProtocol.raw9100),
        );

        final text = latin1.decode(sent.single);
        expect(text, contains('@PJL SET USERID="ana"'));
        expect(text, contains('@PJL SET USERCODE="4321"'));
        expect(text, contains('@PJL SET BILLINGCODE="4321"'));
        expect(text, contains('%PDF-'));
      },
    );

    test('IPP: usa las credenciales guardadas y confirma el trabajo', () async {
      await PrinterCredentialsStore(storage).write(
        _office.address,
        const PrinterCredentials(
          username: 'jperez',
          domain: 'DISMAC',
          password: 'pw',
        ),
      );
      final seen = <String?>[];
      final client = IppClient(
        httpPorts: const [631],
        httpsPorts: const [],
        paths: const ['/ipp/print'],
        jobPollInterval: Duration.zero,
        jobTrackTimeout: Duration.zero,
        transport:
            (
              uri,
              body, {
              String? authorization,
              required Duration timeout,
            }) async {
              seen.add(authorization);
              if (authorization == null) {
                return IppHttpResponse(
                  statusCode: 401,
                  body: Uint8List(0),
                  challenges: const ['Basic realm="RICOH"'],
                );
              }
              final request = IppCodec.decode(body);
              expect(
                request.attribute('requesting-user-name')!.string,
                'jperez',
              );
              if (request.code == IppOperation.getPrinterAttributes) {
                return IppHttpResponse(
                  statusCode: 200,
                  body: ricohAttributesResponse(),
                );
              }
              return IppHttpResponse(
                statusCode: 200,
                body: ippResponse(0, [
                  [
                    IppTag.jobAttributes,
                    ...rec(IppTag.integer, 'job-id', int32(321)),
                  ],
                ]),
              );
            },
      );
      final printer = LabelPrinter(
        storage,
        officePrinter: OfficePrinter(ipp: client),
      );

      final outcome = await printer.printLabel(
        zpl: '',
        render: _render,
        to: _office,
      );

      // El seguimiento no ve estado final → "recibido", nunca "impreso".
      expect(
        outcome.message,
        'La impresora recibió el trabajo (#321) pero no confirmó si lo imprimió. '
        'Revisá que haya salido.',
      );
      expect(seen.first, isNull);
      expect(seen.skip(1), everyElement(startsWith('Basic ')));
    });

    test('IPP cancela en el equipo + hay código de usuario → reintenta por '
        '9100 con USERCODE (Ricoh)', () async {
      await PrinterCredentialsStore(storage).write(
        _office.address,
        const PrinterCredentials(username: 'ehhuallata', userCode: '2468'),
      );
      final raw = <(String, int, Uint8List)>[];
      // IPP: conecta, acepta el Print-Job y lo informa job-state 8 (cancelado).
      final client = IppClient(
        httpPorts: const [631],
        httpsPorts: const [],
        paths: const ['/ipp/print'],
        jobPollInterval: Duration.zero,
        jobTrackTimeout: Duration.zero,
        transport:
            (
              uri,
              body, {
              String? authorization,
              required Duration timeout,
            }) async {
              final request = IppCodec.decode(body);
              if (request.code == IppOperation.getPrinterAttributes) {
                return IppHttpResponse(
                  statusCode: 200,
                  body: ricohUserNameOnlyResponse(),
                );
              }
              // Print-Job aceptado pero cancelado en el equipo.
              return IppHttpResponse(
                statusCode: 200,
                body: ippResponse(0, [
                  [
                    IppTag.jobAttributes,
                    ...rec(IppTag.integer, 'job-id', int32(900)),
                    ...rec(IppTag.enumeration, 'job-state', int32(8)),
                    ...rec(
                      IppTag.keyword,
                      'job-state-reasons',
                      ascii.encode('job-canceled-at-device'),
                    ),
                  ],
                ]),
              );
            },
      );
      final printer = LabelPrinter(
        storage,
        officePrinter: OfficePrinter(
          ipp: client,
          raw: (h, p, b) async => raw.add((h, p, b)),
        ),
      );

      final outcome = await printer.printLabel(
        zpl: '',
        render: _render,
        to: _office, // protocolo IPP
      );

      // Cayó al 9100 con el código de usuario.
      expect(outcome, const PrintOutcome.sentUnconfirmed());
      final (host, port, bytes) = raw.single;
      expect((host, port), ('192.168.2.154', 9100));
      final text = latin1.decode(bytes);
      expect(text, contains('@PJL SET USERCODE="2468"'));
      expect(text, contains('@PJL SET USERID="ehhualla"'));
      expect(text, contains('%PDF-')); // PDF directo, no PCL
    });

    test('IPP cancela pero NO hay código de usuario → no reintenta, propaga el '
        'motivo', () async {
      final client = IppClient(
        httpPorts: const [631],
        httpsPorts: const [],
        paths: const ['/ipp/print'],
        jobPollInterval: Duration.zero,
        jobTrackTimeout: Duration.zero,
        transport:
            (
              uri,
              body, {
              String? authorization,
              required Duration timeout,
            }) async {
              final request = IppCodec.decode(body);
              if (request.code == IppOperation.getPrinterAttributes) {
                return IppHttpResponse(
                  statusCode: 200,
                  body: ricohUserNameOnlyResponse(),
                );
              }
              return IppHttpResponse(
                statusCode: 200,
                body: ippResponse(0, [
                  [
                    IppTag.jobAttributes,
                    ...rec(IppTag.integer, 'job-id', int32(901)),
                    ...rec(IppTag.enumeration, 'job-state', int32(8)),
                    ...rec(
                      IppTag.keyword,
                      'job-state-reasons',
                      ascii.encode('job-canceled-at-device'),
                    ),
                  ],
                ]),
              );
            },
      );
      var rawCalled = false;
      final printer = LabelPrinter(
        storage,
        officePrinter: OfficePrinter(
          ipp: client,
          raw: (h, p, b) async => rawCalled = true,
        ),
      );

      await expectLater(
        printer.printLabel(zpl: '', render: _render, to: _office),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            contains('canceló el trabajo'),
          ),
        ),
      );
      expect(rawCalled, isFalse);
    });
  });

  group('printLabel — Zebra por 9100 con ~HS', () {
    late _Zebra zebra;

    tearDown(() => zebra.close());

    LabelPrinter quick() => LabelPrinter(
      storage,
      zebraStatusTimeout: const Duration(milliseconds: 300),
    );

    test('contesta sin errores → lista', () async {
      zebra = await _Zebra.start(_hs('0', '0'));

      final outcome = await quick().printLabel(zpl: '^XA^XZ', to: zebra.config);

      expect(outcome, const PrintOutcome.ready());
      expect(latin1.decode(zebra.received), '^XA^XZ~HS');
    });

    test('sin papel y cabezal abierto → error con el motivo', () async {
      zebra = await _Zebra.start(_hs('1', '1'));

      await expectLater(
        quick().printLabel(zpl: '^XA^XZ', to: zebra.config),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            contains('sin etiquetas/papel, con el cabezal abierto'),
          ),
        ),
      );
    });

    test('no contesta → enviado sin confirmación', () async {
      zebra = await _Zebra.start();

      final outcome = await quick().printLabel(zpl: '^XA^XZ', to: zebra.config);

      expect(outcome, const PrintOutcome.sentUnconfirmed());
      expect(
        outcome.message,
        'Enviado. Esta impresora no confirma la impresión; revisá que haya '
        'salido.',
      );
    });
  });
}
