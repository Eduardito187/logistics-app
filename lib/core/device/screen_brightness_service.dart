import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brillo de la pantalla SOLO de esta app, vía el canal nativo
/// `bo.com.dismac/screen`:
/// - Android: `WindowManager.LayoutParams.screenBrightness` de la ventana de
///   la Activity (no toca el ajuste del sistema ni pide permisos; al salir de
///   la app el teléfono vuelve solo a su brillo).
/// - iOS: `UIScreen.main.brightness`, guardando el valor previo para volver.
///
/// Se usa al MOSTRAR un QR en pantalla para que otro lo escanee (bajo el sol,
/// con brillo automático bajo, los lectores no lo leen). Nunca falla: sin
/// canal es no-op.
class ScreenBrightnessService {
  const ScreenBrightnessService({MethodChannel channel = defaultChannel})
    : _channel = channel;

  static const MethodChannel defaultChannel = MethodChannel(
    'bo.com.dismac/screen',
  );

  final MethodChannel _channel;

  /// Brillo al máximo mientras dure (hasta [restore]).
  Future<void> boost() => _invoke('boostBrightness');

  /// Vuelve al brillo que tenía el usuario.
  Future<void> restore() => _invoke('restoreBrightness');

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<Object?>(method);
    } on Object {
      // Sin canal (tests, escritorio) o error: el QR se muestra igual.
    }
  }
}

/// Servicio de brillo. Seam para tests (`overrideWithValue`).
final screenBrightnessServiceProvider = Provider<ScreenBrightnessService>(
  (ref) => const ScreenBrightnessService(),
);
