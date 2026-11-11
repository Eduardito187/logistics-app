import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_capabilities.dart';
import 'biometric_result.dart';

/// Biometría del sistema (huella / rostro / iris) vía el canal nativo
/// `bo.com.dismac/biometric` (Android: `BiometricChannel.kt` con
/// androidx.biometric; iOS: `BiometricChannel.swift` con LocalAuthentication).
///
/// Nunca lanza: sin canal (tests, plataforma sin implementación) o ante un
/// error del sistema responde "no soportado" / [BiometricResult.notAvailable].
class BiometricAuthenticator {
  BiometricAuthenticator({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'bo.com.dismac/biometric';

  final MethodChannel _channel;

  /// Qué biometría tiene el teléfono y si hay algo registrado.
  Future<BiometricCapabilities> capabilities() async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'capabilities',
      );
      if (raw == null) return BiometricCapabilities.unsupported;
      return BiometricCapabilities.fromMap(raw);
    } on MissingPluginException {
      return BiometricCapabilities.unsupported;
    } on PlatformException {
      return BiometricCapabilities.unsupported;
    } on Object {
      // Respuesta con forma inesperada: se trata como sin biometría.
      return BiometricCapabilities.unsupported;
    }
  }

  /// Muestra el diálogo del sistema. [reason] va como subtítulo/motivo y
  /// [cancel] es el texto del botón para salir (p. ej. "Usar contraseña").
  Future<BiometricResult> authenticate({
    required String reason,
    String cancel = 'Cancelar',
  }) async {
    try {
      final raw = await _channel.invokeMethod<Object?>('authenticate', {
        'reason': reason,
        'cancel': cancel,
      });
      return BiometricResult.fromWire(raw);
    } on MissingPluginException {
      return BiometricResult.notAvailable;
    } on PlatformException {
      return BiometricResult.notAvailable;
    }
  }
}

/// Seam para tests: se override con un autenticador falso.
final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => BiometricAuthenticator(),
);
