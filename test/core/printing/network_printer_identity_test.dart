import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/network_printer_identity.dart';

// NetworkPrinterIdentity.fromHttpResponse: de la respuesta HTTP cruda de la
// web interna de la impresora saca el nombre (<title>) y si es una Zebra.

/// Respuesta HTTP mínima con [body] como HTML.
String _http(String body) =>
    'HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n$body';

void main() {
  group('NetworkPrinterIdentity.fromHttpResponse — título', () {
    test('Zebra con título: nombre del título e isZebra', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<html><head><title>Zebra ZD421</title></head></html>'),
      );

      expect(id, isNotNull);
      expect(id!.name, 'Zebra ZD421');
      expect(id.isZebra, isTrue);
    });

    test('impresora que no es Zebra: nombre del título, isZebra false', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<html><title>HP LaserJet Pro M404</title></html>'),
      );

      expect(id!.name, 'HP LaserJet Pro M404');
      expect(id.isZebra, isFalse);
    });

    test('etiqueta <TITLE> con atributos y en mayúsculas', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<HTML><TITLE lang="es">Brother QL-820</TITLE></HTML>'),
      );

      expect(id!.name, 'Brother QL-820');
    });

    test('decodifica entidades HTML comunes', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<title>A &amp; B&nbsp;&quot;x&quot; &#39;y&#39;</title>'),
      );

      expect(id!.name, 'A & B "x" \'y\'');
    });

    test('colapsa espacios y saltos de línea y recorta', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<title>\n   Oficina    Anden\t 2 \r\n</title>'),
      );

      expect(id!.name, 'Oficina Anden 2');
    });

    test('título de más de 60 caracteres se corta con …', () {
      final long = 'A' * 75;
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<title>$long</title>'),
      );

      expect(id!.name, '${'A' * 60}…');
    });

    test('título de exactamente 60 caracteres queda entero', () {
      final exact = 'B' * 60;
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<title>$exact</title>'),
      );

      expect(id!.name, exact);
    });
  });

  group('NetworkPrinterIdentity.fromHttpResponse — detección Zebra', () {
    for (final model in ['ZD421', 'ZT230', 'ZQ630', 'GK420', 'zd620']) {
      test('modelo $model sin la marca se reconoce como Zebra', () {
        final id = NetworkPrinterIdentity.fromHttpResponse(
          _http('<title>Printer Home</title><p>Model: $model</p>'),
        );

        expect(id!.isZebra, isTrue);
        expect(id.name, 'Printer Home');
      });
    }

    test('la marca en las cabeceras también cuenta', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        'HTTP/1.0 200 OK\r\nServer: ZEBRA-HTTP\r\n\r\n'
        '<title>Status</title>',
      );

      expect(id!.isZebra, isTrue);
    });

    test('un modelo pegado a otra palabra no es Zebra', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<title>Router</title><p>abcZT230</p>'),
      );

      expect(id!.isZebra, isFalse);
    });
  });

  group('NetworkPrinterIdentity.fromHttpResponse — sin título', () {
    test('sin <title> pero Zebra -> nombre genérico "Zebra"', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<html><body>Zebra Technologies ZT230</body></html>'),
      );

      expect(id, isNotNull);
      expect(id!.name, 'Zebra');
      expect(id.isZebra, isTrue);
    });

    test('título vacío (solo espacios) pero Zebra -> "Zebra"', () {
      final id = NetworkPrinterIdentity.fromHttpResponse(
        _http('<title>   </title><p>ZD421</p>'),
      );

      expect(id!.name, 'Zebra');
      expect(id.isZebra, isTrue);
    });

    test('sin <title> y sin Zebra -> null', () {
      expect(
        NetworkPrinterIdentity.fromHttpResponse(_http('<html>hola</html>')),
        isNull,
      );
    });

    test('título vacío y sin Zebra -> null', () {
      expect(
        NetworkPrinterIdentity.fromHttpResponse(_http('<title></title>')),
        isNull,
      );
    });

    test('respuesta vacía -> null', () {
      expect(NetworkPrinterIdentity.fromHttpResponse(''), isNull);
    });
  });
}
