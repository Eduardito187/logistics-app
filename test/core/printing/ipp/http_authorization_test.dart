import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipp/http_authorization.dart';
import 'package:logistics_app/core/printing/ipp/http_response_parser.dart';
import 'package:logistics_app/core/printing/ipp/md5.dart';

// Autenticación HTTP para IPP (Basic / Digest MD5 escrito a mano) y el parser
// HTTP mínimo del transporte por socket crudo.

void main() {
  group('Md5', () {
    test('vectores de RFC 1321', () {
      expect(Md5.hex(utf8.encode('')), 'd41d8cd98f00b204e9800998ecf8427e');
      expect(Md5.hex(utf8.encode('abc')), '900150983cd24fb0d6963f7d28e17f72');
      expect(
        Md5.hex(utf8.encode('message digest')),
        'f96b697d7cb7938d525a2f31aaf161d0',
      );
      expect(
        Md5.hex(
          utf8.encode(
            '1234567890123456789012345678901234567890'
            '1234567890123456789012345678901234567890',
          ),
        ),
        '57edf4a22be3c955ac49da2e2107b67a',
      );
    });
  });

  group('HttpAuthorization', () {
    test('Basic con dominio: base64("DOMINIO\\usuario:clave")', () {
      expect(
        HttpAuthorization.basic(r'DISMAC\jperez', 'pw'),
        'Basic ${base64.encode(utf8.encode(r'DISMAC\jperez:pw'))}',
      );
    });

    test('Digest: vector de RFC 2617 §3.5', () {
      final params = HttpAuthorization.parseParams(
        'realm="testrealm@host.com", qop="auth,auth-int", '
        'nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", '
        'opaque="5ccc069c403ebaf9f0171e9517f40e41"',
      );
      final header = HttpAuthorization.digest(
        params,
        method: 'GET',
        path: '/dir/index.html',
        user: 'Mufasa',
        password: 'Circle Of Life',
        cnonce: '0a4f113b',
      );
      expect(header, startsWith('Digest '));
      expect(header, contains('response="6629fae49393a05397450978507c4ef1"'));
      expect(header, contains('qop=auth'));
      expect(header, contains('nc=00000001'));
      expect(header, contains('opaque="5ccc069c403ebaf9f0171e9517f40e41"'));
    });

    test('forChallenges prefiere Digest y cae en Basic', () {
      final digest = HttpAuthorization.forChallenges(
        const ['Basic realm="x"', 'Digest realm="x", nonce="n", qop="auth"'],
        method: 'POST',
        path: '/ipp/print',
        user: 'u',
        password: 'p',
        cnonce: 'c',
      );
      expect(digest, startsWith('Digest '));

      final basic = HttpAuthorization.forChallenges(
        const ['Negotiate'],
        method: 'POST',
        path: '/ipp',
        user: 'u',
        password: 'p',
      );
      expect(basic, HttpAuthorization.basic('u', 'p'));
    });
  });

  group('HttpResponseParser', () {
    List<int> raw(String head, [List<int> body = const []]) => [
      ...latin1.encode(head),
      ...body,
    ];

    test('Content-Length: incompleta → null; completa → cuerpo', () {
      final head =
          'HTTP/1.1 200 OK\r\nContent-Type: application/ipp\r\n'
          'Content-Length: 3\r\n\r\n';
      expect(HttpResponseParser.tryParse(raw(head, [1, 2])), isNull);
      final done = HttpResponseParser.tryParse(raw(head, [1, 2, 3]))!;
      expect(done.statusCode, 200);
      expect(done.contentType, 'application/ipp');
      expect(done.body, [1, 2, 3]);
    });

    test('chunked y 100 Continue previo', () {
      final bytes = raw(
        'HTTP/1.1 100 Continue\r\n\r\n'
        'HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n'
        '2\r\n',
        [
          ...[7, 8],
          ...latin1.encode('\r\n1\r\n'),
          9,
          ...latin1.encode('\r\n0\r\n\r\n'),
        ],
      );
      final parsed = HttpResponseParser.tryParse(bytes)!;
      expect(parsed.statusCode, 200);
      expect(parsed.body, [7, 8, 9]);
    });

    test('401 con desafío', () {
      final parsed = HttpResponseParser.tryParse(
        raw(
          'HTTP/1.1 401 Unauthorized\r\n'
          'WWW-Authenticate: Basic realm="RICOH"\r\n'
          'Content-Length: 0\r\n\r\n',
        ),
      )!;
      expect(parsed.statusCode, 401);
      expect(parsed.challenges, ['Basic realm="RICOH"']);
    });

    test('sin largo: el cuerpo termina al cerrar', () {
      final bytes = raw('HTTP/1.0 200 OK\r\n\r\n', [5, 6]);
      expect(HttpResponseParser.tryParse(bytes), isNull);
      expect(HttpResponseParser.tryParse(bytes, closed: true)!.body, [5, 6]);
    });

    test('no es HTTP → FormatException', () {
      expect(
        () => HttpResponseParser.tryParse(raw('basura\r\n\r\n')),
        throwsFormatException,
      );
    });
  });
}
