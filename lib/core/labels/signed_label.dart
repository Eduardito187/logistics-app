import 'dart:convert';

import 'label_format_exception.dart';
import 'label_payload.dart';

/// Payload + firma Ed25519, tal como se lee del QR.
class SignedLabel {
  SignedLabel(this.payload, List<int> signature)
    : signature = List.unmodifiable(signature) {
    if (signature.length != signatureBytes) {
      throw LabelFormatException('la firma Ed25519 debe tener 64 bytes');
    }
  }

  static const int signatureBytes = 64;

  final LabelPayload payload;
  final List<int> signature;

  /// Reconstruye la etiqueta desde el texto del QR. Valida formato, NO la firma.
  factory SignedLabel.fromQrContent(String content) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw LabelFormatException('el contenido del QR no es JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw LabelFormatException('el contenido del QR no es un objeto');
    }

    final version = _int(decoded, 'v');
    if (version != LabelPayload.currentVersion) {
      throw LabelFormatException('versión no soportada: $version');
    }
    final type = LabelType.fromCode(_string(decoded, 't'));
    if (type != LabelType.package) {
      throw LabelFormatException(
        'solo se soportan etiquetas de tipo PKG por ahora',
      );
    }

    final payload = LabelPayload(
      version: version,
      type: type!,
      keyId: _int(decoded, 'k'),
      id: _string(decoded, 'id'),
      orderNumber: _string(decoded, 'o'),
      lineNumber: _int(decoded, 'ln'),
      sku: _string(decoded, 'sku'),
      unit: _fraction(decoded, 'u'),
      piece: _fraction(decoded, 'pc'),
      origin: _string(decoded, 'org'),
      destination: _string(decoded, 'dst'),
      issuedAt: _int(decoded, 'ts'),
    );

    return SignedLabel(payload, _base64UrlDecode(_string(decoded, 's')));
  }

  static int _int(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! int) {
      throw LabelFormatException("campo '$key' debe ser entero");
    }
    return value;
  }

  static String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) {
      throw LabelFormatException("campo '$key' debe ser texto");
    }
    return value;
  }

  static Fraction _fraction(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! List ||
        value.length != 2 ||
        value[0] is! int ||
        value[1] is! int) {
      throw LabelFormatException("campo '$key' debe ser [índice, total]");
    }
    return Fraction(value[0] as int, value[1] as int);
  }

  static List<int> _base64UrlDecode(String text) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(text)) {
      throw LabelFormatException('la firma no está en base64url');
    }
    try {
      return base64Url.decode(base64Url.normalize(text));
    } on FormatException {
      throw LabelFormatException('la firma no está en base64url');
    }
  }
}
