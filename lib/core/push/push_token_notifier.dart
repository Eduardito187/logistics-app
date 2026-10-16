import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/token_store.dart';

/// Token FCM del dispositivo, persistido en el secure storage compartido.
///
/// Es el gancho para el login: el flujo de autenticación lee este valor y lo
/// envía como `device.push_token` en `api.auth.appLogin`. El `PushController`
/// lo escribe al obtenerlo (y en cada rotación de FCM).
class PushTokenNotifier extends Notifier<String?> {
  static const String _tokenKey = 'push_token';

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  /// Hubo un save/clear: la carga diferida ya no debe pisar ese estado.
  bool _touched = false;

  @override
  String? build() {
    // Carga diferida: el estado nace en null y se completa al leer el storage.
    _touched = false;
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final String? saved = await _storage.read(key: _tokenKey);
    if (!_touched && saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  /// Guarda el token recibido de FCM (persistente + en memoria).
  Future<void> save(String token) async {
    _touched = true;
    state = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Borra el token (baja del push en este dispositivo).
  Future<void> clear() async {
    _touched = true;
    state = null;
    await _storage.delete(key: _tokenKey);
  }
}

/// Token push (FCM) actual del dispositivo. El login lo envía como
/// `device.push_token`; `null` mientras no haya registro.
final pushTokenProvider = NotifierProvider<PushTokenNotifier, String?>(
  PushTokenNotifier.new,
);
