import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ulid/ulid.dart';

/// Almacén seguro del token Bearer (Sanctum) y del identificador de dispositivo.
///
/// El token va por usuario + dispositivo (puerta `/app/*`). El `deviceId` se
/// genera una sola vez por instalación y acompaña a los escaneos.
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'app_bearer_token';
  static const _deviceIdKey = 'device_id';
  static const _sessionKey = 'app_session';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  /// Copia de la sesión (nombre, rol, abilities) para reabrir la app logueado
  /// tras cerrarla o reiniciar el teléfono, incluso sin señal. `null` si no hay
  /// o si está corrupta.
  Future<Map<String, Object?>?> readSessionSnapshot() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeSessionSnapshot(Map<String, Object?> snapshot) =>
      _storage.write(key: _sessionKey, value: jsonEncode(snapshot));

  Future<void> clearSessionSnapshot() => _storage.delete(key: _sessionKey);

  /// Identificador estable del dispositivo. Se crea (ULID) la primera vez.
  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = Ulid().toString();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    // resetOnError: si la clave del Keystore quedó inservible (p. ej. tras
    // reinstalar o restaurar un backup) y no se puede descifrar, limpia el
    // almacén y sigue (se pide login) en vez de volcar un SecurityException.
    aOptions: AndroidOptions(resetOnError: true),
  ),
);

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(secureStorageProvider)),
);
