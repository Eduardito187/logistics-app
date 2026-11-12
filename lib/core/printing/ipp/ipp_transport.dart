import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'http_response_parser.dart';
import 'ipp_http_response.dart';

/// Hace un POST `application/ipp` y devuelve la respuesta cruda. Seam para
/// tests. Ante fallas de conexión (sin ruta, rechazo, timeout, TLS) lanza
/// [SocketException], [TimeoutException] o [TlsException]: el cliente las
/// trata como "este puerto no responde".
typedef IppTransport =
    Future<IppHttpResponse> Function(
      Uri uri,
      Uint8List body, {
      String? authorization,
      required Duration timeout,
    });

/// Transporte real: HTTP/1.1 sobre socket crudo de dart:io.
///
/// Socket crudo a propósito (igual que la identificación por HTTP de la
/// búsqueda): `HttpClient` respeta la política de tráfico en claro de Android
/// (en release bloquea todo `http://`, pensada para el backend) y no dejaría
/// hablar IPP con la impresora de la LAN. Por HTTPS acepta el certificado
/// autofirmado de la impresora (no hay CA que lo valide); solo se usa contra
/// la IP de la impresora, nunca contra la API.
Future<IppHttpResponse> httpIppTransport(
  Uri uri,
  Uint8List body, {
  String? authorization,
  required Duration timeout,
}) async {
  final secure = uri.scheme == 'https';
  final Socket socket = secure
      ? await SecureSocket.connect(
          uri.host,
          uri.port,
          timeout: const Duration(seconds: 4),
          onBadCertificate: (_) => true,
        )
      : await Socket.connect(
          uri.host,
          uri.port,
          timeout: const Duration(seconds: 4),
        );
  final received = <int>[];
  final done = Completer<IppHttpResponse>();
  void tryComplete({bool closed = false}) {
    if (done.isCompleted) return;
    try {
      final parsed = HttpResponseParser.tryParse(received, closed: closed);
      if (parsed != null) done.complete(parsed);
    } on FormatException catch (e) {
      done.completeError(e);
    }
  }

  final sub = socket.listen(
    (chunk) {
      received.addAll(chunk);
      tryComplete();
    },
    onDone: () => tryComplete(closed: true),
    onError: (Object e) {
      if (!done.isCompleted) done.completeError(e);
    },
    cancelOnError: true,
  );
  try {
    final path = uri.path.isEmpty ? '/' : uri.path;
    final head = StringBuffer()
      ..write('POST $path HTTP/1.1\r\n')
      ..write('Host: ${uri.host}:${uri.port}\r\n')
      ..write('User-Agent: DisTrack\r\n')
      ..write('Content-Type: application/ipp\r\n')
      ..write('Accept: application/ipp\r\n')
      ..write('Content-Length: ${body.length}\r\n')
      ..write('Connection: close\r\n');
    if (authorization != null) head.write('Authorization: $authorization\r\n');
    head.write('\r\n');
    socket
      ..add(utf8.encode(head.toString()))
      ..add(body);
    await socket.flush().timeout(timeout);
    return await done.future.timeout(timeout);
  } finally {
    socket.destroy();
    await sub.cancel();
  }
}
