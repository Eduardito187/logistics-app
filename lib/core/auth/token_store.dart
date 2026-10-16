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

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

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
  (ref) => const FlutterSecureStorage(),
);

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(secureStorageProvider)),
);
