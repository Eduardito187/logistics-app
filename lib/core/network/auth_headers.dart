import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_headers_data.dart';

// Se reexporta el modelo [AuthHeaders] (movido a su propio archivo por SRP) para
// no romper a quienes importan `network/auth_headers.dart`.
export 'auth_headers_data.dart';

class AuthHeadersNotifier extends Notifier<AuthHeaders> {
  @override
  AuthHeaders build() => const AuthHeaders();

  void setToken(String? token) => state = token == null
      ? state.copyWith(clearToken: true)
      : state.copyWith(bearerToken: token);

  void setDeviceId(String deviceId) =>
      state = state.copyWith(deviceId: deviceId);
}

final authHeadersProvider = NotifierProvider<AuthHeadersNotifier, AuthHeaders>(
  AuthHeadersNotifier.new,
);
