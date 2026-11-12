import Flutter
import Foundation
import UIKit
#if canImport(WidgetKit)
  import WidgetKit
#endif

/// Widgets de la pantalla de inicio (WidgetKit). Contraparte Dart: lib/core/home_widgets/
/// (canal "bo.com.dismac/widgets"). Los widgets viven en la extensión
/// ios/RouteLiveActivity/HomeWidgets/ y leen lo que la app deja en el App Group.
///
/// Dart → nativo:
/// - "isSupported" → {"pinSupported": false} (iOS no deja anclar widgets desde la app)
/// - "update" {"kind", "payload"} → guarda el payload (JSON) en el App Group, clave
///   "widget.<kind>", y recarga SOLO ese widget.
/// - "clearAll" → cada kind queda {"state": "signedOut"} y se recargan todos.
/// - "setEnabledKinds" → no-op (la galería de widgets de iOS no se puede filtrar).
/// - "requestPin" → false.
///
/// El `kind` de cada Widget (WidgetConfiguration) es EXACTAMENTE el mismo string que
/// usa Dart ("next_delivery", "route_day", …), así no hace falta un mapeo.
///
/// Deep link: los widgets abren "distrack://open?route=<ruta>" y el botón Navegar
/// "distrack://navigate?daddr=<lat>,<lng>". AppDelegate reenvía
/// `application(_:open:options:)` a [handle(url:)].
enum WidgetsChannel {
  private static let channelName = "bo.com.dismac/widgets"
  /// Debe coincidir con el App Group de Runner.entitlements y
  /// RouteLiveActivity.entitlements (y con WidgetStore.appGroup en la extensión).
  static let appGroup = "group.bo.com.dismac.logisticsApp"
  static let urlScheme = "distrack"
  static let kinds = [
    "next_delivery",
    "route_day",
    "picking_pending",
    "store_receptions",
    "supervisor_summary",
    "quick_scan",
  ]

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isSupported":
        result(["pinSupported": false])
      case "update":
        let args = call.arguments as? [String: Any]
        guard let kind = args?["kind"] as? String, !kind.isEmpty else {
          result(FlutterError(code: "bad_args", message: "Falta 'kind'", details: nil))
          return
        }
        let payload = (args?["payload"] as? [String: Any]) ?? ["state": "empty"]
        result(save(kind: kind, payload: payload))
        reload(kind: kind)
      case "clearAll":
        for kind in kinds {
          save(kind: kind, payload: ["state": "signedOut"])
        }
        reloadAll()
        result(true)
      case "setEnabledKinds":
        result(nil)
      case "requestPin":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Deep link distrack://

  /// Llamar desde AppDelegate.application(_:open:options:). Devuelve false si la URL
  /// no es del esquema distrack:// (así AppDelegate se la pasa a super/plugins).
  ///
  /// - distrack://open?route=/ruta → entrega la ruta a Dart por el mismo camino que los
  ///   accesos del ícono (AppShortcutsChannel.deliver: pendiente en frío, "launch" en
  ///   caliente). Sin route válida solo abre la app.
  /// - distrack://navigate?daddr=lat,lng → abre Apple Maps con el destino (los Link de
  ///   un widget siempre abren la app contenedora, no otra app; por eso se reenvía).
  @discardableResult
  static func handle(url: URL) -> Bool {
    guard url.scheme?.lowercased() == urlScheme else { return false }
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func query(_ name: String) -> String? {
      items.first(where: { $0.name == name })?.value
    }
    switch (url.host ?? "").lowercased() {
    case "navigate":
      if let daddr = query("daddr"), !daddr.isEmpty {
        openMaps(daddr: daddr)
      }
      return true
    default:
      // "open" (o cualquier otro host): abrir la app y, si hay ruta, navegar.
      if let route = query("route"), route.hasPrefix("/") {
        AppShortcutsChannel.deliver(route: route)
      }
      return true
    }
  }

  private static func openMaps(daddr: String) {
    // "lat,lng": solo dígitos, punto, coma y signo → no hace falta más escape.
    let allowed = CharacterSet(charactersIn: "0123456789.,-+")
    let clean = String(daddr.unicodeScalars.filter { allowed.contains($0) })
    guard !clean.isEmpty, let url = URL(string: "maps://?daddr=\(clean)") else { return }
    // Esperar un ciclo: con la app recién abierta, open() en el mismo tick a veces
    // se ignora mientras la escena pasa a activa.
    DispatchQueue.main.async {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  // MARK: - App Group

  @discardableResult
  private static func save(kind: String, payload: [String: Any]) -> Bool {
    guard let defaults = UserDefaults(suiteName: appGroup) else { return false }
    var json = payload
    if json["state"] == nil { json["state"] = "ok" }
    if json["updatedAt"] == nil {
      json["updatedAt"] = Int(Date().timeIntervalSince1970 * 1000)
    }
    guard JSONSerialization.isValidJSONObject(json),
      let data = try? JSONSerialization.data(withJSONObject: json)
    else { return false }
    defaults.set(data, forKey: "widget.\(kind)")
    return true
  }

  // MARK: - Recarga (solo cuando la app manda datos: timelines con policy .never)

  private static func reload(kind: String) {
    #if canImport(WidgetKit)
      // WidgetKit existe desde iOS 14 y la app pide 15.0: no hace falta #available.
      WidgetCenter.shared.reloadTimelines(ofKind: kind)
    #endif
  }

  private static func reloadAll() {
    #if canImport(WidgetKit)
      WidgetCenter.shared.reloadAllTimelines()
    #endif
  }
}
