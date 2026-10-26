import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'signed_label.dart';
import 'verification_result.dart';

// Se reexporta [VerificationResult] (movido a su propio archivo por SRP) para no
// romper a quienes importan `labels/label_verifier.dart`.
export 'verification_result.dart';

/// Verifica la firma Ed25519 de una etiqueta SIN internet.
///
/// Trae varias claves públicas a la vez: así las etiquetas impresas con la clave
/// anterior siguen siendo válidas durante una rotación.
class LabelVerifier {
  LabelVerifier(Map<int, List<int>> publicKeys)
    : _publicKeys = _buildKeys(publicKeys);

  /// Valida el largo ANTES de construir [SimplePublicKey]: así el error es
  /// siempre nuestro [ArgumentError] y no depende de si la versión de
  /// `cryptography` valida (o no) en su constructor.
  static Map<int, SimplePublicKey> _buildKeys(Map<int, List<int>> publicKeys) {
    for (final entry in publicKeys.entries) {
      if (entry.value.length != 32) {
        throw ArgumentError(
          'La clave pública ${entry.key} debe tener 32 bytes.',
        );
      }
    }
    return {
      for (final entry in publicKeys.entries)
        entry.key: SimplePublicKey(entry.value, type: KeyPairType.ed25519),
    };
  }

  /// Construye el verificador desde "id:base64,id:base64" (mismo formato que el backend).
  factory LabelVerifier.fromConfig(String raw) =>
      LabelVerifier(parseConfig(raw));

  /// Parsea "id:base64,id:base64" (mismo formato que el backend) a bytes por id.
  /// Lo comparte la fuente combinada de claves (config + caché + backend).
  static Map<int, List<int>> parseConfig(String raw) {
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
    return keys;
  }

  final Map<int, SimplePublicKey> _publicKeys;
  final Ed25519 _algorithm = Ed25519();

  /// Resultados ya calculados por (clave, mensaje, firma). El escaneo continuo
  /// relee la misma etiqueta varias veces (cámara apoyada sobre el bulto) y la
  /// verificación Ed25519 en Dart puro cuesta milisegundos en el isolate de UI;
  /// el resultado es determinista, así que se reusa. Tope chico (LRU simple).
  final Map<String, VerificationResult> _cache = <String, VerificationResult>{};

  /// Entradas máximas de [_cache] (~ una descarga grande de bultos).
  static const int cacheSize = 256;

  Future<VerificationResult> verify(SignedLabel label) async {
    final publicKey = _publicKeys[label.payload.keyId];
    if (publicKey == null) {
      return VerificationResult.unknownKey;
    }

    final message = label.payload.canonical();
    final cacheKey =
        '${label.payload.keyId}|${base64.encode(label.signature)}|$message';
    final cached = _cache.remove(cacheKey);
    if (cached != null) {
      _cache[cacheKey] = cached; // vuelve al final (más reciente)
      return cached;
    }

    final ok = await _algorithm.verify(
      utf8.encode(message),
      signature: Signature(label.signature, publicKey: publicKey),
    );

    final result = ok
        ? VerificationResult.valid
        : VerificationResult.invalidSignature;
    if (_cache.length >= cacheSize) _cache.remove(_cache.keys.first);
    _cache[cacheKey] = result;
    return result;
  }
}

/// Vacía la caché de resultados de [verifier] (tests y benchmark).
@visibleForTesting
void clearLabelVerifierCache(LabelVerifier verifier) => verifier._cache.clear();

/// Entradas en la caché de resultados de [verifier] (tests).
@visibleForTesting
int labelVerifierCacheLength(LabelVerifier verifier) => verifier._cache.length;
