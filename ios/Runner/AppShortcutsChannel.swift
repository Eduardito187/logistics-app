import Flutter
import UIKit

/// Accesos directos del ícono (toque largo en el ícono de la app). Contraparte
/// Dart: lib/core/shortcuts/.
///
/// Dart → nativo:
/// - "set" (lista de {id, title, shortTitle, route}) → Bool
/// - "clear" → Bool (al cerrar sesión)
/// - "consumeLaunchShortcut" → ruta con la que se abrió la app, o nil (una vez)
/// Nativo → Dart:
/// - "launch" (ruta) cuando se toca un acceso con la app ya corriendo.
///
/// AppDelegate debe reenviar `application(_:performActionFor:completionHandler:)`
/// a [handle] (ver docs/live-updates.md).
enum AppShortcutsChannel {
  private static let channelName = "bo.com.dismac/shortcuts"
  private static let routeKey = "route"
  private static var channel: FlutterMethodChannel?
  private static var pendingRoute: String?
  /// Dart ya preguntó por el acceso de arranque: los siguientes van por "launch".
  private static var dartReady = false

  static func register(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "set":
        let items = (call.arguments as? [[String: Any]]) ?? []
        UIApplication.shared.shortcutItems = items.compactMap(shortcutItem)
        result(true)
      case "clear":
        UIApplication.shared.shortcutItems = []
        result(true)
      case "consumeLaunchShortcut":
        dartReady = true
        let route = pendingRoute
        pendingRoute = nil
        result(route)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = methodChannel
  }

  /// Llamar desde AppDelegate.performActionFor. En frío guarda la ruta hasta
  /// que Dart la pida; con la app corriendo se la pasa a Dart al toque.
  @discardableResult
  static func handle(_ item: UIApplicationShortcutItem) -> Bool {
    guard let route = item.userInfo?[routeKey] as? String else { return false }
    return deliver(route: route)
  }

  /// Entrega una ruta de go_router a Dart por el mismo camino que los accesos
  /// del ícono: en frío queda pendiente hasta "consumeLaunchShortcut"; con la
  /// app corriendo va por "launch". La usan también los widgets de inicio
  /// (WidgetsChannel.handle(url:), esquema distrack://).
  @discardableResult
  static func deliver(route: String) -> Bool {
    guard route.hasPrefix("/") else { return false }
    if dartReady, let channel = channel {
      channel.invokeMethod("launch", arguments: route)
    } else {
      pendingRoute = route
    }
    return true
  }

  private static func shortcutItem(_ map: [String: Any]) -> UIApplicationShortcutItem? {
    guard let id = map["id"] as? String,
      let title = map["title"] as? String,
      let route = map["route"] as? String
    else { return nil }
    return UIApplicationShortcutItem(
      type: "bo.com.dismac.shortcut.\(id)",
      localizedTitle: title,
      localizedSubtitle: nil,
      icon: UIApplicationShortcutIcon(systemImageName: symbol(for: id)),
      userInfo: [routeKey: route as NSString]
    )
  }

  /// SF Symbol por acceso (todos existen en iOS 15, el mínimo de la app;
  /// "truck.box" es de iOS 16 → se usa "shippingbox").
  private static func symbol(for id: String) -> String {
    switch id {
    case "driver-active-delivery": return "shippingbox.fill"
    case "driver-route": return "map.fill"
    case "driver-load": return "qrcode.viewfinder"
    case "driver-incident": return "exclamationmark.triangle.fill"
    case "picking-orders": return "list.bullet.rectangle"
    case "picking-prepare": return "barcode.viewfinder"
    case "store-reception": return "tray.and.arrow.down.fill"
    case "store-pickup": return "bag.fill"
    case "carrier-pickup": return "arrow.up.bin.fill"
    case "carrier-deliver": return "checkmark.seal.fill"
    case "sup-fleet": return "location.fill"
    case "sup-alerts": return "bell.fill"
    case "sup-dashboard": return "chart.bar.fill"
    default: return "app.fill"
    }
  }
}
