import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/token_store.dart';

/// Caché local de las claves públicas de etiquetas en `flutter_secure_storage`.
///
/// Guarda las claves ya traídas del backend como `{id: base64}` para que la
/// verificación Ed25519 del escaneo funcione offline tras el primer fetch.
/// Reusa la misma instancia de almacén (`secureStorageProvider`) que el token.
class LabelKeyStore {
  LabelKeyStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _cacheKey = 'label_public_keys';

  /// Lee las claves cacheadas como `{id: base64}`. Si no hay nada o la caché
  /// quedó corrupta, devuelve un mapa vacío (nunca rompe el escaneo).
  Future<Map<int, String>> read() async {
    final raw = await _storage.read(key: _cacheKey);
    if (raw == null || raw.isEmpty) {
      return <int, String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <int, String>{};
      }
      final result = <int, String>{};
      decoded.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is String) {
          result[id] = value;
        }
      });
      return result;
    } on FormatException {
      return <int, String>{};
    }
  }

  /// Persiste la unión de claves `{id: base64}`.
  Future<void> write(Map<int, String> keys) {
    final json = <String, String>{
      for (final entry in keys.entries) '${entry.key}': entry.value,
    };
    return _storage.write(key: _cacheKey, value: jsonEncode(json));
  }
}

final labelKeyStoreProvider = Provider<LabelKeyStore>(
  (ref) => LabelKeyStore(ref.watch(secureStorageProvider)),
);
