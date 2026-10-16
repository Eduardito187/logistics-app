import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Motivo del último cierre de sesión forzado (p. ej. un 401 del backend).
///
/// Queda expuesto para que una capa superior de la UI muestre un aviso
/// ("Tu sesión expiró, volvé a ingresar") y luego lo limpie con [clear].
/// `null` = no hay aviso pendiente.
class SessionExpiredNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String message) => state = message;

  void clear() => state = null;
}

final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, String?>(
      SessionExpiredNotifier.new,
    );
