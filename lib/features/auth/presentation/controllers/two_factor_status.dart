import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/token_store.dart';

/// Estado local de "2FA activo". El backend NO expone el flag en `/app/auth/me`,
/// así que se deduce de las acciones (confirmar/desactivar) y se persiste en el
/// almacén seguro para mostrarlo en Ajustes › Seguridad al reabrir la app.
///
/// Es una pista de UI (no una fuente de verdad de seguridad): el backend sigue
/// siendo quien exige el 2FA en el login.
class TwoFactorEnabledNotifier extends AsyncNotifier<bool> {
  static const _key = 'two_factor_enabled';

  @override
  Future<bool> build() async {
    try {
      final value = await ref.read(secureStorageProvider).read(key: _key);
      return value == 'true';
    } on Object {
      return false;
    }
  }

  /// Marca el 2FA como activo/inactivo (tras confirmar o desactivar).
  Future<void> set({required bool enabled}) async {
    state = AsyncData(enabled);
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: _key, value: enabled ? 'true' : 'false');
    } on Object {
      // Si el almacén falla, el estado en memoria ya quedó actualizado.
    }
  }
}

final twoFactorEnabledProvider =
    AsyncNotifierProvider<TwoFactorEnabledNotifier, bool>(
      TwoFactorEnabledNotifier.new,
    );
