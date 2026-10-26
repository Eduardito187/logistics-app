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

  /// Todo el almacén leído de UNA vez al arrancar ([preload]). En Android cada
  /// lectura cruza al Keystore (decenas–cientos de ms en gama baja); con esto
  /// el arranque paga una sola y token, sesión, dispositivo y preferencias
  /// salen de memoria. `null` si no se precargó o si `readAll` falló (se lee
  /// clave por clave como antes).
  Future<Map<String, String>?>? _all;

  /// Lanza la lectura completa del almacén (idempotente). `main.dart` la
  /// dispara lo antes posible, en paralelo con el resto del arranque.
  Future<void> preload() async {
    _all ??= _storage.readAll().then<Map<String, String>?>(
      (all) => Map<String, String>.of(all),
      onError: (Object _) => null,
    );
    await _all;
  }

  Future<String?> _read(String key) async {
    final all = await _all;
    if (all != null) return all[key];
    return _storage.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    (await _all)?[key] = value;
    await _storage.write(key: key, value: value);
  }

  Future<void> _delete(String key) async {
    (await _all)?.remove(key);
    await _storage.delete(key: key);
  }

  /// Preferencia del dispositivo guardada en el almacén (p. ej. alto
  /// contraste); sale de memoria si el almacén ya se precargó.
  Future<String?> readPref(String key) => _read(key);

  Future<String?> readToken() => _read(_tokenKey);

  Future<void> writeToken(String token) => _write(_tokenKey, token);

  Future<void> clearToken() => _delete(_tokenKey);

  /// Copia de la sesión (nombre, rol, abilities) para reabrir la app logueado
  /// tras cerrarla o reiniciar el teléfono, incluso sin señal. `null` si no hay
  /// o si está corrupta.
  Future<Map<String, Object?>?> readSessionSnapshot() async {
    final raw = await _read(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeSessionSnapshot(Map<String, Object?> snapshot) =>
      _write(_sessionKey, jsonEncode(snapshot));

  Future<void> clearSessionSnapshot() => _delete(_sessionKey);

  /// Identificador estable del dispositivo. Se crea (ULID) la primera vez y
  /// queda en memoria: el login y los escaneos no vuelven al almacén.
  Future<String> deviceId() => _deviceId ??= _loadDeviceId();

  Future<String>? _deviceId;

  Future<String> _loadDeviceId() async {
    final existing = await _read(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = Ulid().toString();
    await _write(_deviceIdKey, generated);
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
