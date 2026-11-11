import Flutter
import UIKit

/// Brillo de la pantalla al MOSTRAR un QR para que otro lo escanee. Contraparte
/// Dart: lib/core/device/screen_brightness_service.dart.
///
/// - "boostBrightness" → guarda el brillo del usuario y lo sube al máximo
/// - "restoreBrightness" → vuelve al brillo guardado
///
/// iOS NO restituye solo el brillo al salir de la app: se baja al pasar a
/// segundo plano y se vuelve a subir al regresar (si el QR sigue en pantalla).
/// Lo registra LiveUpdatesChannel.register (no hace falta tocar AppDelegate).
enum ScreenChannel {
  private static let channelName = "bo.com.dismac/screen"
  private static var savedBrightness: CGFloat?
  private static var observersInstalled = false

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "boostBrightness":
        boost()
        result(true)
      case "restoreBrightness":
        restore()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    installObservers()
  }

  private static func boost() {
    if savedBrightness == nil {
      savedBrightness = UIScreen.main.brightness
    }
    UIScreen.main.brightness = 1.0
  }

  private static func restore() {
    guard let saved = savedBrightness else { return }
    UIScreen.main.brightness = saved
    savedBrightness = nil
  }

  private static func installObservers() {
    guard !observersInstalled else { return }
    observersInstalled = true
    let center = NotificationCenter.default
    center.addObserver(
      forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
    ) { _ in
      // Se sale de la app: brillo del usuario, pero se recuerda el boost.
      if let saved = savedBrightness {
        UIScreen.main.brightness = saved
      }
    }
    center.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in
      if savedBrightness != nil {
        UIScreen.main.brightness = 1.0
      }
    }
  }
}
