import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipp/ipp_attribute.dart';
import 'package:logistics_app/core/printing/ipp/ipp_attribute_group.dart';
import 'package:logistics_app/core/printing/ipp/ipp_client.dart';
import 'package:logistics_app/core/printing/ipp/ipp_codec.dart';
import 'package:logistics_app/core/printing/ipp/ipp_endpoint.dart';
import 'package:logistics_app/core/printing/ipp/ipp_message.dart';
import 'package:logistics_app/core/printing/ipp/ipp_operation.dart';
import 'package:logistics_app/core/printing/ipp/ipp_printer_info.dart';
import 'package:logistics_app/core/printing/ipp/ipp_resolution.dart';
import 'package:logistics_app/core/printing/ipp/ipp_status.dart';
import 'package:logistics_app/core/printing/ipp/ipp_tags.dart';

import 'ipp_test_bytes.dart';

// Codificación binaria IPP (RFC 8010) contra bytes conocidos, a mano.

void main() {
  group('IppCodec.encode', () {
    test('Get-Printer-Attributes: bytes exactos', () {
      final message = IppMessage(
        code: IppOperation.getPrinterAttributes,
        requestId: 1,
        groups: [
          IppAttributeGroup(IppTag.operationAttributes, [
            IppAttribute('attributes-charset', IppTag.charset, ['utf-8']),
            IppAttribute(
              'attributes-natural-language',
              IppTag.naturalLanguage,
              ['es'],
            ),
            IppAttribute('printer-uri', IppTag.uri, [
              'ipp://h:631/ipp/print',
            ]),
            IppAttribute('requested-attributes', IppTag.keyword, [
              'printer-state',
              'document-format-supported',
            ]),
          ]),
        ],
      );

      final expected = <int>[
        0x01, 0x01, // versión 1.1
        0x00, 0x0B, // Get-Printer-Attributes
        0x00, 0x00, 0x00, 0x01, // request-id
        0x01, // operation-attributes
        0x47, 0x00, 0x12, ...ascii.encode('attributes-charset'),
        0x00, 0x05, ...ascii.encode('utf-8'),
        0x48, 0x00, 0x1B, ...ascii.encode('attributes-natural-language'),
        0x00, 0x02, ...ascii.encode('es'),
        0x45, 0x00, 0x0B, ...ascii.encode('printer-uri'),
        0x00, 0x15, ...ascii.encode('ipp://h:631/ipp/print'),
        0x44, 0x00, 0x14, ...ascii.encode('requested-attributes'),
        0x00, 0x0D, ...ascii.encode('printer-state'),
        // Valor adicional: nombre vacío.
        0x44, 0x00, 0x00,
        0x00, 0x19, ...ascii.encode('document-format-supported'),
        0x03, // fin de atributos
      ];
      expect(IppCodec.encode(message), expected);
    });

    test('enteros, booleanos y resolución', () {
      final message = IppMessage(
        code: 0,
        requestId: 7,
        groups: [
          IppAttributeGroup(IppTag.jobAttributes, [
            IppAttribute('copies', IppTag.integer, [2]),
            IppAttribute('flag', IppTag.boolean, [true]),
            IppAttribute('res', IppTag.resolution, [
              const IppResolution(300, 600),
            ]),
          ]),
        ],
        data: Uint8List.fromList([9, 9]),
      );
      final bytes = IppCodec.encode(message);
      final back = IppCodec.decode(bytes);
      expect(back.requestId, 7);
      expect(back.attribute('copies')!.integer, 2);
      expect(back.attribute('flag')!.values.single, isTrue);
      expect(
        back.attribute('res')!.values.single,
        const IppResolution(300, 600),
      );
      expect(back.data, [9, 9]);
    });

    test('Print-Job del cliente lleva usuario, job-name, formato y datos', () {
      final client = IppClient();
      const endpoint = IppEndpoint(host: 'h', port: 631, path: '/ipp/print');
      final request = client.printJobRequest(
        endpoint,
        userName: 'jperez',
        jobName: 'Etiqueta 1234',
        documentFormat: 'application/pdf',
        data: Uint8List.fromList([1, 2, 3]),
      );
      final decoded = IppCodec.decode(IppCodec.encode(request));
      expect(decoded.code, IppOperation.printJob);
      expect(decoded.attribute('attributes-charset')!.string, 'utf-8');
      expect(decoded.attribute('attributes-natural-language')!.string, 'es');
      expect(
        decoded.attribute('printer-uri')!.string,
        'ipp://h:631/ipp/print',
      );
      expect(decoded.attribute('requesting-user-name')!.string, 'jperez');
      expect(decoded.attribute('job-name')!.string, 'Etiqueta 1234');
      expect(
        decoded.attribute('document-format')!.string,
        'application/pdf',
      );
      expect(decoded.data, [1, 2, 3]);
    });
  });

  group('IppCodec.decode', () {
    test('respuesta de impresora con formatos y autenticación', () {
      final response = IppCodec.decode(ricohAttributesResponse());

      expect(response.code, IppStatus.successfulOk);
      expect(response.requestId, 1);
      final info = IppPrinterInfo.fromMessage(response);
      expect(info.makeAndModel, 'RICOH IM 550');
      expect(info.state, IppPrinterInfo.stateIdle);
      expect(info.stateReasons, ['none']);
      expect(info.documentFormats, [
        'application/pdf',
        'image/pwg-raster',
        'application/octet-stream',
      ]);
      expect(info.authenticationSupported, ['basic']);
      expect(info.requiresCredentials, isTrue);
      expect(info.isAcceptingJobs, isTrue);
      expect(info.pwgResolutions, [const IppResolution(300, 300)]);
      expect(info.problem, isNull);
      // La colección se saltea y lo que sigue se lee bien.
      expect(response.attribute('queued-job-count')!.integer, 2);
    });

    test('estado detenido con motivos → problema en español', () {
      final info = IppPrinterInfo.fromMessage(
        IppCodec.decode(
          ippResponse(IppStatus.successfulOk, [
            printerGroup([
              rec(IppTag.enumeration, 'printer-state', int32(5)),
              rec(
                IppTag.keyword,
                'printer-state-reasons',
                ascii.encode('media-empty-error'),
              ),
              rec(IppTag.keyword, '', ascii.encode('cover-open')),
            ]),
          ]),
        ),
      );
      expect(info.problem, 'La impresora está sin papel, con la tapa abierta.');
    });

    test('truncada o sin fin de atributos → FormatException', () {
      final good = ricohAttributesResponse();
      expect(
        () => IppCodec.decode(Uint8List.sublistView(good, 0, 30)),
        throwsFormatException,
      );
      expect(
        () => IppCodec.decode(Uint8List.fromList([1, 1, 0, 0])),
        throwsFormatException,
      );
    });
  });

  group('IppStatus', () {
    test('mensajes en español por código', () {
      expect(IppStatus.isSuccess(0x0001), isTrue);
      expect(IppStatus.isSuccess(0x0400), isFalse);
      expect(
        IppStatus.message(IppStatus.clientErrorDocumentFormatNotSupported),
        'La impresora no acepta el formato del documento.',
      );
      expect(
        IppStatus.message(IppStatus.serverErrorBusy),
        contains('ocupada'),
      );
      expect(
        IppStatus.message(IppStatus.clientErrorNotAuthenticated),
        contains('usuario de dominio'),
      );
      expect(IppStatus.message(0x04FF), contains('0x04ff'));
    });
  });
}
