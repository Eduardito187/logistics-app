import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_role.dart';

class Session {
  const Session({required this.userName, required this.role});

  final String userName;
  final UserRole role;
}

/// Sesión actual. `null` = sin sesión.
///
/// El login real (token por usuario + dispositivo contra /api/v1/app/auth) se conecta
/// cuando el backend exponga ese endpoint. Mientras tanto, solo existe la entrada de desarrollo.
class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Solo para builds de desarrollo: entra con un rol sin pasar por el backend.
  void devSignIn(UserRole role) {
    state = Session(userName: 'dev.${role.name}', role: role);
  }

  void signOut() {
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);
