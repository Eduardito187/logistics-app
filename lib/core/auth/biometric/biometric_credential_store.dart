import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../token_store.dart';
import 'biometric_credential.dart';

/// Almacén de la credencial para ingresar con biometría y de las cuentas que
/// respondieron "Ahora no" a la oferta post-login.
///
/// UNA sola cuenta por teléfono: en teléfonos compartidos cualquier huella
/// registrada podría abrir cualquier cuenta guardada, así que guardar otra
/// reemplaza a la anterior. Ninguna lectura lanza: almacén ilegible = sin
/// credencial (se ingresa con contraseña).
class BiometricCredentialStore {
  BiometricCredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  static const credentialKey = 'biometric_credential';
  static const declinedKey = 'biometric_declined';

  Future<BiometricCredential?> read() async {
    try {
      final raw = await _storage.read(key: credentialKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?>
          ? BiometricCredential.fromJson(decoded)
          : null;
    } on Object {
      return null;
    }
  }

  /// Guarda [credential] reemplazando la de cualquier otra cuenta.
  Future<void> save(BiometricCredential credential) => _storage.write(
    key: credentialKey,
    value: jsonEncode(credential.toJson()),
  );

  Future<void> clear() async {
    try {
      await _storage.delete(key: credentialKey);
    } on Object {
      // Best-effort: si no se pudo borrar, el próximo login fallido la borra.
    }
  }

  /// ¿Esta cuenta ya dijo "Ahora no" a la oferta post-login?
  Future<bool> hasDeclined(String email) async =>
      (await _declined()).contains(_normalize(email));

  /// Recuerda el "Ahora no" de esta cuenta (no se vuelve a ofrecer).
  Future<void> markDeclined(String email) async {
    final declined = await _declined()
      ..add(_normalize(email));
    await _writeDeclined(declined);
  }

  /// Olvida el "Ahora no" (p. ej. al activarlo desde el perfil).
  Future<void> clearDeclined(String email) async {
    final declined = await _declined();
    if (!declined.remove(_normalize(email))) return;
    await _writeDeclined(declined);
  }

  Future<Set<String>> _declined() async {
    try {
      final raw = await _storage.read(key: declinedKey);
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.whereType<String>().toSet() : <String>{};
    } on Object {
      return <String>{};
    }
  }

  Future<void> _writeDeclined(Set<String> declined) async {
    try {
      await _storage.write(
        key: declinedKey,
        value: jsonEncode(declined.toList()..sort()),
      );
    } on Object {
      // Sin persistir: a lo sumo se vuelve a ofrecer en el próximo login.
    }
  }

  static String _normalize(String email) => email.trim().toLowerCase();
}

final biometricCredentialStoreProvider = Provider<BiometricCredentialStore>(
  (ref) => BiometricCredentialStore(ref.watch(secureStorageProvider)),
);
