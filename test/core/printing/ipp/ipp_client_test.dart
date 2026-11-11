import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipp/ipp_client.dart';
import 'package:logistics_app/core/printing/ipp/ipp_codec.dart';
import 'package:logistics_app/core/printing/ipp/ipp_message.dart';
import 'package:logistics_app/core/printing/ipp/ipp_operation.dart';
import 'package:logistics_app/core/printing/ipp/ipp_status.dart';
import 'package:logistics_app/core/printing/ipp/ipp_tags.dart';
import 'package:logistics_app/core/printing/office/label_raster.dart';
import 'package:logistics_app/core/printing/print_outcome.dart';
import 'package:logistics_app/core/printing/printer_credentials.dart';
import 'package:logistics_app/core/printing/printer_exception.dart';

import 'ipp_test_bytes.dart';

// Cliente IPP contra una "impresora" HttpServer en 127.0.0.1: autenticación
// (401 → Basic, status 0x0402 → Basic), rutas, formatos y errores. El
// transporte real (HTTP/1.1 por socket crudo) se ejercita de punta a punta.

/// Un pedido recibido por la impresora falsa.
class _Seen {
  _Seen(this.path, this.authorization, this.message);

  final String path;
  final String? authorization;
  final IppMessage message;

  int get operation => message.code;
  String? get format => message.attribute('document-format')?.string;
}

/// Respuesta de la impresora falsa.
class _Reply {
  const _Reply.ipp(this.body, {this.chunked = false})
    : status = 200,
      challenge = null;

  const _Reply.http(this.status, {this.challenge})
    : body = null,
      chunked = false;

  final int status;
  final Uint8List? body;
  final String? challenge;
  final bool chunked;
}

typedef _Handler = _Reply Function(_Seen seen);

class _FakeIppPrinter {
  _FakeIppPrinter._(this._server, this.handler) {
    _server.listen((request) async {
      final bytes = await request.fold<List<int>>(
        <int>[],
        (all, chunk) => all..addAll(chunk),
      );
      final seen = _Seen(
        request.uri.path,
        request.headers.value(HttpHeaders.authorizationHeader),
        IppCodec.decode(Uint8List.fromList(bytes)),
      );
      requests.add(seen);
      final reply = handler(seen);
      final response = request.response..statusCode = reply.status;
      if (reply.challenge != null) {
        response.headers.set(
          HttpHeaders.wwwAuthenticateHeader,
          reply.challenge!,
        );
      }
      final body = reply.body;
      if (body != null) {
        response.headers.contentType = ContentType('application', 'ipp');
        // Sin largo → "chunked" (prueba el des-chunkeo del transporte).
        if (!reply.chunked) response.contentLength = body.length;
        response.add(body);
      }
      await response.close();
    });
  }

  static Future<_FakeIppPrinter> start(_Handler handler) async =>
      _FakeIppPrinter._(
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        handler,
      );

  final HttpServer _server;
  final _Handler handler;
  final List<_Seen> requests = [];

  int get port => _server.port;

  Future<void> close() => _server.close(force: true);
}

const _creds = PrinterCredentials(
  username: 'jperez',
  domain: 'DISMAC',
  password: 'pw',
);

final _expectedBasic =
    'Basic ${base64.encode(utf8.encode(r'DISMAC\jperez:pw'))}';

Uint8List _jobResponse(int jobId, {int state = 3, int status = 0}) =>
    ippResponse(status, [
      [
        IppTag.jobAttributes,
        ...rec(IppTag.integer, 'job-id', int32(jobId)),
        ...rec(IppTag.enumeration, 'job-state', int32(state)),
      ],
    ]);

Uint8List _status(int status) => ippResponse(status, const []);

LabelRaster _raster() => LabelRaster(
  width: 8,
  height: 8,
  dpi: 100,
  pixels: Uint8List.fromList(List<int>.generate(64, (i) => i.isEven ? 0 : 255)),
);

// Seguimiento del trabajo sin esperas: una sola consulta y listo.
IppClient _client(int port, {List<String> paths = const ['/ipp/print']}) =>
    IppClient(
      httpPorts: [port],
      httpsPorts: const [],
      paths: paths,
      jobPollInterval: Duration.zero,
      jobTrackTimeout: Duration.zero,
    );

void main() {
  late _FakeIppPrinter printer;

  tearDown(() => printer.close());

  test('Print-Job: 401 → Basic con DOMINIO\\usuario y acepta', () async {
    printer = await _FakeIppPrinter.start((seen) {
      if (seen.authorization == null) {
        return const _Reply.http(401, challenge: 'Basic realm="RICOH"');
      }
      expect(seen.authorization, _expectedBasic);
      return seen.operation == IppOperation.getPrinterAttributes
          ? _Reply.ipp(ricohAttributesResponse(), chunked: true)
          : _Reply.ipp(_jobResponse(123));
    });
    final client = _client(printer.port);

    final connection = await client.connect(
      '127.0.0.1',
      userName: 'jperez',
      credentials: _creds,
    );
    expect(connection.authenticated, isTrue);
    expect(connection.info.makeAndModel, 'RICOH IM 550');

    final outcome = await client.printRaster(
      connection,
      _raster(),
      jobName: 'Etiqueta 1234',
      userName: 'jperez',
      credentials: _creds,
    );

    // El seguimiento (Get-Job-Attributes) sigue viendo "pendiente" y vence:
    // se informa recibido/procesando, nunca "impreso".
    expect(outcome, const PrintOutcome.accepted(jobId: 123));
    expect(
      outcome.message,
      'La impresora recibió el trabajo (#123) pero no confirmó si lo imprimió. '
        'Revisá que haya salido.',
    );
    // GPA sin auth (401) + GPA con auth + Print-Job + Get-Job-Attributes.
    expect(printer.requests, hasLength(4));
    expect(printer.requests.last.operation, IppOperation.getJobAttributes);
    final job = printer.requests[2];
    expect(job.operation, IppOperation.printJob);
    expect(job.authorization, _expectedBasic);
    expect(job.format, 'application/pdf');
    expect(
      job.message.attribute('requesting-user-name')!.string,
      'jperez',
    );
    expect(job.message.attribute('job-name')!.string, 'Etiqueta 1234');
    expect(ascii.decode(job.message.data.sublist(0, 5)), '%PDF-');
  });

  test('401 sin credenciales → pide el usuario de dominio', () async {
    printer = await _FakeIppPrinter.start(
      (_) => const _Reply.http(401, challenge: 'Basic realm="RICOH"'),
    );

    await expectLater(
      _client(printer.port).connect('127.0.0.1', userName: 'x'),
      throwsA(
        isA<PrinterException>()
            .having((e) => e.needsSetup, 'needsSetup', isTrue)
            .having(
              (e) => e.message,
              'message',
              contains('usuario de dominio'),
            ),
      ),
    );
  });

  test('usuario sin contraseña → pide la contraseña', () async {
    printer = await _FakeIppPrinter.start(
      (_) => const _Reply.http(401, challenge: 'Basic realm="RICOH"'),
    );

    await expectLater(
      _client(printer.port).connect(
        '127.0.0.1',
        userName: 'jperez',
        credentials: const PrinterCredentials(username: 'jperez'),
      ),
      throwsA(
        isA<PrinterException>().having(
          (e) => e.message,
          'message',
          contains('contraseña de «jperez»'),
        ),
      ),
    );
  });

  test('contraseña incorrecta (401 de nuevo) → rechazo claro', () async {
    printer = await _FakeIppPrinter.start(
      (_) => const _Reply.http(401, challenge: 'Basic realm="RICOH"'),
    );

    await expectLater(
      _client(
        printer.port,
      ).connect('127.0.0.1', userName: 'jperez', credentials: _creds),
      throwsA(
        isA<PrinterException>().having(
          (e) => e.message,
          'message',
          contains(r'rechazó el usuario «DISMAC\jperez»'),
        ),
      ),
    );
    expect(printer.requests, hasLength(2));
  });

  test('status 0x0402 (not-authenticated) → reintenta Basic', () async {
    printer = await _FakeIppPrinter.start((seen) {
      if (seen.authorization == null) {
        return _Reply.ipp(_status(IppStatus.clientErrorNotAuthenticated));
      }
      return _Reply.ipp(ricohAttributesResponse());
    });

    final connection = await _client(
      printer.port,
    ).connect('127.0.0.1', userName: 'jperez', credentials: _creds);

    expect(connection.authorization, _expectedBasic);
    expect(printer.requests.map((r) => r.authorization), [
      null,
      _expectedBasic,
    ]);
  });

  test('0x0403 (not-authorized) con credenciales → sin permiso', () async {
    printer = await _FakeIppPrinter.start(
      (_) => _Reply.ipp(_status(IppStatus.clientErrorNotAuthorized)),
    );

    await expectLater(
      _client(
        printer.port,
      ).connect('127.0.0.1', userName: 'jperez', credentials: _creds),
      throwsA(
        isA<PrinterException>().having(
          (e) => e.message,
          'message',
          contains('no autoriza al usuario'),
        ),
      ),
    );
  });

  test('ruta: /ipp/print da 404 y /ipp responde', () async {
    printer = await _FakeIppPrinter.start(
      (seen) => seen.path == '/ipp'
          ? _Reply.ipp(ricohAttributesResponse())
          : const _Reply.http(404),
    );

    final connection = await _client(
      printer.port,
      paths: const ['/ipp/print', '/ipp'],
    ).connect('127.0.0.1', userName: 'x');

    expect(connection.endpoint.path, '/ipp');
    expect(
      connection.endpoint.printerUri,
      'ipp://127.0.0.1:${printer.port}/ipp',
    );
    expect(connection.authenticated, isFalse);
  });

  test('PDF rechazado por formato → reintenta con PWG raster', () async {
    printer = await _FakeIppPrinter.start((seen) {
      if (seen.operation == IppOperation.getPrinterAttributes) {
        return _Reply.ipp(ricohAttributesResponse());
      }
      if (seen.format == 'application/pdf') {
        return _Reply.ipp(
          _status(IppStatus.clientErrorDocumentFormatNotSupported),
        );
      }
      return _Reply.ipp(_jobResponse(7));
    });
    final client = _client(printer.port);
    final connection = await client.connect('127.0.0.1', userName: 'x');

    final outcome = await client.printRaster(
      connection,
      _raster(),
      jobName: 'Prueba',
      userName: 'x',
    );

    expect(outcome.jobId, 7);
    // El último pedido es el seguimiento; el trabajo es el último Print-Job.
    final last = printer.requests.lastWhere(
      (r) => r.operation == IppOperation.printJob,
    );
    expect(last.format, 'image/pwg-raster');
    expect(ascii.decode(last.message.data.sublist(0, 4)), 'RaS2');
  });

  test('trabajo abortado por la impresora → error', () async {
    printer = await _FakeIppPrinter.start(
      (seen) => seen.operation == IppOperation.getPrinterAttributes
          ? _Reply.ipp(ricohAttributesResponse())
          : _Reply.ipp(_jobResponse(9, state: 8)),
    );
    final client = _client(printer.port);
    final connection = await client.connect('127.0.0.1', userName: 'x');

    await expectLater(
      client.printRaster(connection, _raster(), jobName: 'J', userName: 'x'),
      throwsA(
        isA<PrinterException>().having(
          (e) => e.message,
          'message',
          contains('canceló el trabajo'),
        ),
      ),
    );
  });

  group('seguimiento del trabajo (aceptado ≠ impreso)', () {
    Uint8List jobAttrs(int state, {String? reason}) => ippResponse(0, [
      [
        IppTag.jobAttributes,
        ...rec(IppTag.enumeration, 'job-state', int32(state)),
        if (reason != null)
          ...rec(IppTag.keyword, 'job-state-reasons', ascii.encode(reason)),
      ],
    ]);

    Future<PrintOutcome> printWith(
      Uint8List Function() printerAttrs,
      Uint8List Function() jobState,
    ) async {
      printer = await _FakeIppPrinter.start((seen) {
        if (seen.operation == IppOperation.getPrinterAttributes) {
          return _Reply.ipp(printerAttrs());
        }
        if (seen.operation == IppOperation.getJobAttributes) {
          expect(seen.message.attribute('job-id')!.integer, 744);
          return _Reply.ipp(jobState());
        }
        // Print-Job: aceptado y "procesando" (como la Ricoh real).
        return _Reply.ipp(_jobResponse(744, state: 5));
      });
      final client = _client(printer.port);
      final connection = await client.connect('127.0.0.1', userName: 'x');
      return client.printRaster(
        connection,
        _raster(),
        jobName: 'J',
        userName: 'ehhuallata',
      );
    }

    test('estado 9 → "Impreso" confirmado', () async {
      final outcome = await printWith(
        ricohAttributesResponse,
        () => jobAttrs(9, reason: 'job-completed-successfully'),
      );
      expect(outcome, const PrintOutcome.printed(jobId: 744));
      expect(outcome.message, startsWith('Impreso'));
    });

    test('caso real Ricoh: aceptado y luego job-canceled-at-device con IPP '
        'solo por nombre → explica la autenticación', () async {
      await expectLater(
        printWith(
          ricohUserNameOnlyResponse,
          () => jobAttrs(8, reason: 'job-canceled-at-device'),
        ),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('exige iniciar sesión'),
              contains('Autenticación IPP'),
            ),
          ),
        ),
      );
    });

    test('con IPP Basic: cancelado en la impresora → revisar credenciales', () async {
      await expectLater(
        printWith(
          ricohAttributesResponse,
          () => jobAttrs(7, reason: 'job-canceled-at-device'),
        ),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.message,
            'message',
            contains('no aceptó tu usuario o contraseña'),
          ),
        ),
      );
    });

    test('estado 4 → retenido: liberar en el panel', () async {
      final outcome = await printWith(
        ricohAttributesResponse,
        () => jobAttrs(4, reason: 'job-hold-until-specified'),
      );
      expect(outcome, const PrintOutcome.held(jobId: 744));
      expect(outcome.message, contains('liberalo desde el panel'));
    });

    test('la consulta falla → "recibido", nunca "impreso"', () async {
      final outcome = await printWith(
        ricohAttributesResponse,
        () => _status(IppStatus.serverErrorBusy),
      );
      expect(outcome.kind, PrintOutcomeKind.accepted);
      expect(outcome.message, contains('no confirmó si lo imprimió'));
    });
  });

  test('impresora ocupada → mensaje en español', () async {
    printer = await _FakeIppPrinter.start(
      (seen) => seen.operation == IppOperation.getPrinterAttributes
          ? _Reply.ipp(ricohAttributesResponse())
          : _Reply.ipp(_status(IppStatus.serverErrorBusy)),
    );
    final client = _client(printer.port);
    final connection = await client.connect('127.0.0.1', userName: 'x');

    await expectLater(
      client.printRaster(connection, _raster(), jobName: 'J', userName: 'x'),
      throwsA(
        isA<PrinterException>().having(
          (e) => e.message,
          'message',
          contains('ocupada'),
        ),
      ),
    );
  });

  test('ningún puerto IPP responde → SocketException', () async {
    printer = await _FakeIppPrinter.start((_) => const _Reply.http(500));
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();

    await expectLater(
      _client(port).connect('127.0.0.1', userName: 'x'),
      throwsA(isA<SocketException>()),
    );
  });

  test('candidatos: la ruta conocida primero, luego HTTP y HTTPS', () {
    final list = IppClient().candidates('h', path: '/printer', port: 631);
    expect(list.first.printerUri, 'ipp://h:631/printer');
    expect(list.map((e) => e.printerUri), contains('ipp://h:631/ipp/print'));
    expect(list.map((e) => e.printerUri), contains('ipps://h:443/ipp/print'));
    expect(list.last.tls, isTrue);
  });
}
