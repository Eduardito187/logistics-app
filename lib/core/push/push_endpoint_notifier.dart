import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/token_store.dart';

/// Endpoint push del dispositivo, persistido en el secure storage compartido.
///
/// Es el gancho para el login: el flujo de autenticación lee este valor y lo
/// envía como `device.push_token` en `api.auth.appLogin`. El backend no expone
/// (todavía) un endpoint para actualizar el push_token de un dispositivo ya
/// registrado —solo `GET /app/devices` para listarlos—, así que el endpoint
/// viaja en el login. El `PushController` lo escribe al recibir un endpoint.
class PushEndpointNotifier extends Notifier<String?> {
  static const String _endpointKey = 'push_endpoint';

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  String? build() {
    // Carga diferida: el estado nace en null y se completa al leer el storage.
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final String? saved = await _storage.read(key: _endpointKey);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  /// Guarda el endpoint recibido del distribuidor (persistente + en memoria).
  Future<void> save(String endpoint) async {
    state = endpoint;
    await _storage.write(key: _endpointKey, value: endpoint);
  }

  /// Borra el endpoint (baja del distribuidor).
  Future<void> clear() async {
    state = null;
    await _storage.delete(key: _endpointKey);
  }
}

/// Endpoint push actual del dispositivo. El login lo envía como
/// `device.push_token`; `null` mientras no haya registro.
final pushEndpointProvider = NotifierProvider<PushEndpointNotifier, String?>(
  PushEndpointNotifier.new,
);
