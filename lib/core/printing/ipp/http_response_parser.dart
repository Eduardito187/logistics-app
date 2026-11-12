import 'dart:convert';
import 'dart:typed_data';

import 'ipp_http_response.dart';

/// Parser mínimo de respuestas HTTP/1.x (status, cabeceras, cuerpo con
/// `Content-Length` o `chunked`). Lo usa el transporte IPP por socket crudo.
abstract final class HttpResponseParser {
  /// Respuesta completa dentro de [bytes], o `null` si todavía faltan datos.
  /// Con [closed] (el servidor cerró) se acepta el cuerpo hasta el final.
  /// Saltea respuestas intermedias `1xx` (p. ej. `100 Continue`).
  static IppHttpResponse? tryParse(List<int> bytes, {bool closed = false}) {
    var start = 0;
    while (true) {
      final headerEnd = _indexOf(bytes, const [13, 10, 13, 10], start);
      if (headerEnd < 0) {
        if (closed) throw const FormatException('Respuesta HTTP incompleta');
        return null;
      }
      final head = latin1.decode(bytes.sublist(start, headerEnd));
      final lines = head.split('\r\n');
      final status = RegExp(r'^HTTP/\d\.\d\s+(\d{3})').firstMatch(lines.first);
      if (status == null) {
        throw const FormatException('No es una respuesta HTTP');
      }
      final code = int.parse(status.group(1)!);
      final bodyStart = headerEnd + 4;
      if (code >= 100 && code < 200) {
        start = bodyStart;
        continue;
      }
      final headers = <String, List<String>>{};
      for (final line in lines.skip(1)) {
        final colon = line.indexOf(':');
        if (colon <= 0) continue;
        final key = line.substring(0, colon).trim().toLowerCase();
        final value = line.substring(colon + 1).trim();
        headers.putIfAbsent(key, () => []).add(value);
      }
      final body = _body(bytes, bodyStart, headers, closed: closed);
      if (body == null) return null;
      final type = headers['content-type']?.first.split(';').first.trim();
      return IppHttpResponse(
        statusCode: code,
        body: body,
        contentType: type?.toLowerCase(),
        challenges: headers['www-authenticate'] ?? const [],
      );
    }
  }

  static Uint8List? _body(
    List<int> bytes,
    int start,
    Map<String, List<String>> headers, {
    required bool closed,
  }) {
    final encoding = headers['transfer-encoding']?.join(',').toLowerCase();
    if (encoding != null && encoding.contains('chunked')) {
      return _dechunk(bytes, start, closed: closed);
    }
    final length = int.tryParse(headers['content-length']?.first ?? '');
    if (length != null) {
      if (bytes.length - start < length) {
        if (closed) throw const FormatException('Cuerpo HTTP truncado');
        return null;
      }
      return Uint8List.fromList(bytes.sublist(start, start + length));
    }
    // Sin largo: el cuerpo termina cuando el servidor cierra.
    return closed ? Uint8List.fromList(bytes.sublist(start)) : null;
  }

  static Uint8List? _dechunk(
    List<int> bytes,
    int start, {
    required bool closed,
  }) {
    final out = BytesBuilder(copy: false);
    var pos = start;
    while (true) {
      final lineEnd = _indexOf(bytes, const [13, 10], pos);
      if (lineEnd < 0) break;
      final sizeText = latin1.decode(bytes.sublist(pos, lineEnd)).split(';');
      final size = int.tryParse(sizeText.first.trim(), radix: 16);
      if (size == null) throw const FormatException('Chunk HTTP inválido');
      final dataStart = lineEnd + 2;
      if (size == 0) return out.takeBytes();
      if (bytes.length < dataStart + size + 2) break;
      out.add(bytes.sublist(dataStart, dataStart + size));
      pos = dataStart + size + 2;
    }
    if (closed) throw const FormatException('Cuerpo HTTP truncado');
    return null;
  }

  static int _indexOf(List<int> bytes, List<int> pattern, int from) {
    outer:
    for (var i = from; i <= bytes.length - pattern.length; i++) {
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}
