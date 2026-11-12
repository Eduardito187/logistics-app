import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Decide si el login lanza solo el diálogo de biometría al abrirse.
///
/// Criterio: SOLO la primera vez que se muestra el login en esta apertura de
/// la app (arranque en frío sin sesión). Después de un cierre de sesión manual
/// NO se lanza: el usuario acaba de salir a propósito (p. ej. para que entre
/// otro) y un prompt inmediato lo volvería a meter con un toque. El botón
/// "Ingresar con …" sigue disponible siempre.
class BiometricAutoPromptGate {
  bool _used = false;

  /// `true` solo la primera vez que se pide (y si no se suprimió antes).
  bool consume() {
    if (_used) return false;
    _used = true;
    return true;
  }

  /// Cierre de sesión manual: el próximo login no lanza el prompt solo.
  void suppress() => _used = true;
}

final biometricAutoPromptGateProvider = Provider<BiometricAutoPromptGate>(
  (ref) => BiometricAutoPromptGate(),
);
