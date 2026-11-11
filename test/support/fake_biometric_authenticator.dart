import 'package:logistics_app/core/auth/biometric/biometric_authenticator.dart';
import 'package:logistics_app/core/auth/biometric/biometric_capabilities.dart';
import 'package:logistics_app/core/auth/biometric/biometric_result.dart';
import 'package:logistics_app/core/auth/biometric/biometric_type.dart';

/// Huella Android registrada y lista para usar.
const kFingerprintReady = BiometricCapabilities(
  supported: true,
  enrolled: true,
  types: {BiometricType.fingerprint},
);

/// Biometría sin canal nativo: responde lo que el test fije, sin plataforma.
/// Se inyecta con `biometricAuthenticatorProvider.overrideWithValue(fake)`.
class FakeBiometricAuthenticator extends BiometricAuthenticator {
  FakeBiometricAuthenticator({
    this.caps = kFingerprintReady,
    this.result = BiometricResult.success,
  });

  BiometricCapabilities caps;
  BiometricResult result;

  int authenticateCalls = 0;
  String? lastReason;
  String? lastCancel;

  @override
  Future<BiometricCapabilities> capabilities() async => caps;

  @override
  Future<BiometricResult> authenticate({
    required String reason,
    String cancel = 'Cancelar',
  }) async {
    authenticateCalls++;
    lastReason = reason;
    lastCancel = cancel;
    return result;
  }
}
