import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_authenticator.dart';
import 'biometric_capabilities.dart';
import 'biometric_credential.dart';
import 'biometric_credential_store.dart';
import 'biometric_result.dart';

/// Cuenta habilitada para ingresar con biometría en este teléfono (`null` =
/// ninguna). La comparten el login (botón "Ingresar con …") y el perfil
/// (switch). Se borra al desactivar el switch, cuando la contraseña guardada
/// deja de servir o cuando otra cuenta la activa; NO al cerrar sesión.
class BiometricCredentialNotifier extends AsyncNotifier<BiometricCredential?> {
  BiometricCredentialStore get _store =>
      ref.read(biometricCredentialStoreProvider);

  @override
  Future<BiometricCredential?> build() =>
      ref.watch(biometricCredentialStoreProvider).read();

  /// Activa el ingreso con biometría para esta cuenta: primero pide la
  /// biometría (confirma que funciona y que es el dueño del teléfono) y, si
  /// pasa, guarda la credencial reemplazando la de cualquier otra cuenta.
  Future<BiometricResult> enable({
    required String email,
    required String password,
    required BiometricCapabilities capabilities,
    String? name,
  }) async {
    // Que la lectura inicial no pise después lo que se guarda acá.
    await future;
    final result = await ref
        .read(biometricAuthenticatorProvider)
        .authenticate(
          reason: 'Confirmá ${capabilities.labelWithArticle} para activarlo',
          cancel: 'Cancelar',
        );
    if (result != BiometricResult.success) return result;
    final credential = BiometricCredential(
      email: email.trim(),
      password: password,
      name: name,
    );
    try {
      await _store.save(credential);
    } on Object {
      return BiometricResult.failed;
    }
    unawaited(_store.clearDeclined(email));
    if (ref.mounted) state = AsyncData(credential);
    return result;
  }

  /// Tras un login con contraseña OK de la MISMA cuenta guardada: si la
  /// contraseña cambió (p. ej. la reseteó), se actualiza en silencio para que
  /// la biometría siga funcionando. Otra cuenta → no toca nada.
  Future<void> syncPassword({
    required String email,
    required String password,
  }) async {
    final current = await future;
    if (current == null || !current.isFor(email)) return;
    if (current.password == password) return;
    final updated = BiometricCredential(
      email: current.email,
      password: password,
      name: current.name,
    );
    try {
      await _store.save(updated);
    } on Object {
      return;
    }
    if (ref.mounted) state = AsyncData(updated);
  }

  /// Desactiva el ingreso con biometría (borra la credencial guardada).
  Future<void> disable() async {
    await future;
    await _store.clear();
    if (ref.mounted) state = const AsyncData(null);
  }
}

final biometricCredentialProvider =
    AsyncNotifierProvider<BiometricCredentialNotifier, BiometricCredential?>(
      BiometricCredentialNotifier.new,
    );
