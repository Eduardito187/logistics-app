import Flutter
import UIKit

/// Canal nativo de energía: nivel de batería, si está cargando y si el modo
/// de bajo consumo está activo. Contraparte Dart: lib/core/power/power_channel.dart.
///
/// - "status" → {level: Int 0-100 (-1 si no se pudo leer), charging: Bool,
///   powerSave: Bool}
///
/// Consulta puntual: Dart la repite al volver a primer plano y, durante la
/// ruta, cada pocos minutos. No deja observadores registrados.
enum PowerChannel {
  private static let channelName = "bo.com.dismac/power"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "status":
        result(status())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func status() -> [String: Any] {
    let device = UIDevice.current
    // Sin esto iOS devuelve -1 / .unknown. Habilitarlo no consume: solo
    // permite leer el estado que el sistema ya conoce.
    if !device.isBatteryMonitoringEnabled {
      device.isBatteryMonitoringEnabled = true
    }
    let raw = device.batteryLevel  // 0.0...1.0, o -1 si es desconocido
    let level = raw < 0 ? -1 : Int((raw * 100).rounded())
    let charging = device.batteryState == .charging || device.batteryState == .full
    return [
      "level": level,
      "charging": charging,
      "powerSave": ProcessInfo.processInfo.isLowPowerModeEnabled,
    ]
  }
}
