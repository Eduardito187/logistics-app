import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';

/// Preferencia "Alto contraste (sol)" del dispositivo, persistida en el
/// almacén seguro (sobrevive a cerrar sesión y reiniciar el teléfono).
///
/// Arranca en `false` y carga el valor guardado en segundo plano: el primer
/// cuadro nunca espera al almacén. Si el usuario cambia el valor antes de que
/// termine la carga, gana el cambio del usuario.
class HighContrastNotifier extends Notifier<bool> {
  /// Clave en el almacén seguro.
  static const storageKey = 'pref_high_contrast';

  bool _changedByUser = false;

  @override
  bool build() {
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(secureStorageProvider).read(key: storageKey);
      if (!ref.mounted || _changedByUser || raw == null) return;
      state = raw == 'true';
    } on Object {
      // Almacén no disponible (test sin plugin, keystore dañado): queda el
      // valor por defecto. Es una preferencia visual, no es crítica.
    }
  }

  /// Activa o desactiva el alto contraste y lo guarda.
  Future<void> set(bool value) async {
    _changedByUser = true;
    state = value;
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: storageKey, value: value.toString());
    } on Object {
      // Si no se pudo guardar, igual rige para esta sesión de la app.
    }
  }

  Future<void> toggle() => set(!state);
}

/// `true` si el tema de alto contraste está activo. `app.dart` lo usa para
/// elegir `AppTheme.highContrast()` en lugar de `AppTheme.light()`.
final highContrastProvider = NotifierProvider<HighContrastNotifier, bool>(
  HighContrastNotifier.new,
);
