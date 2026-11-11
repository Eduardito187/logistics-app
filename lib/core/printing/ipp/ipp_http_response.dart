import 'dart:typed_data';

/// Respuesta HTTP cruda de un POST IPP.
class IppHttpResponse {
  const IppHttpResponse({
    required this.statusCode,
    required this.body,
    this.contentType,
    this.challenges = const [],
  });

  final int statusCode;
  final Uint8List body;

  /// `Content-Type` (sin parámetros), p. ej. `application/ipp`.
  final String? contentType;

  /// Cabeceras `WWW-Authenticate` (en un 401).
  final List<String> challenges;
}
