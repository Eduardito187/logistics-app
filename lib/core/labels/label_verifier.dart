import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'signed_label.dart';

enum VerificationResult {
  valid,

  /// La firma no corresponde al contenido: etiqueta editada o fabricada.
  invalidSignature,

  /// El id de clave ("k") no está entre las claves públicas que trae la app.
  unknownKey;

  bool get isValid => this == valid;
}

/// Verifica la firma Ed25519 de una etiqueta SIN internet.
///
/// Trae varias claves públicas a la vez: así las etiquetas impresas con la clave
/// anterior siguen siendo válidas durante una rotación.
class LabelVerifier {
  LabelVerifier(Map<int, List<int>> publicKeys)
    : _publicKeys = {
        for (final entry in publicKeys.entries)
          entry.key: SimplePublicKey(entry.value, type: KeyPairType.ed25519),
      } {
    for (final entry in publicKeys.entries) {
      if (entry.value.length != 32) {
        throw ArgumentError(
          'La clave pública ${entry.key} debe tener 32 bytes.',
        );
      }
    }
  }

  /// Construye el verificador desde "id:base64,id:base64" (mismo formato que el backend).
  factory LabelVerifier.fromConfig(String raw) {
    final keys = <int, List<int>>{};
    for (final entry
        in raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      final separator = entry.indexOf(':');
      final id = separator > 0
          ? int.tryParse(entry.substring(0, separator))
          : null;
      if (id == null) {
        throw ArgumentError('Entrada de clave pública inválida: $entry');
      }
      keys[id] = base64.decode(entry.substring(separator + 1));
    }
    return LabelVerifier(keys);
  }

  final Map<int, SimplePublicKey> _publicKeys;
  final Ed25519 _algorithm = Ed25519();

  Future<VerificationResult> verify(SignedLabel label) async {
    final publicKey = _publicKeys[label.payload.keyId];
    if (publicKey == null) {
      return VerificationResult.unknownKey;
    }

    final ok = await _algorithm.verify(
      utf8.encode(label.payload.canonical()),
      signature: Signature(label.signature, publicKey: publicKey),
    );

    return ok ? VerificationResult.valid : VerificationResult.invalidSignature;
  }
}
