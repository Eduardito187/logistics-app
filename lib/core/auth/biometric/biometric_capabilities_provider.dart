import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_authenticator.dart';
import 'biometric_capabilities.dart';

/// Biometría del teléfono. autoDispose: se vuelve a consultar al reabrir el
/// login o el perfil (y al volver a la app, ver los `AppLifecycleListener`),
/// por si el usuario registró o borró una huella en los ajustes del teléfono.
final biometricCapabilitiesProvider =
    FutureProvider.autoDispose<BiometricCapabilities>(
      (ref) => ref.watch(biometricAuthenticatorProvider).capabilities(),
    );
