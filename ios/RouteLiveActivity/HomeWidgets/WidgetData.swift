import Foundation
import SwiftUI
import WidgetKit

// Base compartida de los widgets de inicio: lector del App Group, proveedor de
// timeline genérico, deep links y estilos de marca. La app (Runner/WidgetsChannel.swift)
// escribe; la extensión solo lee.

// MARK: - Kinds (idénticos a los de Dart y a WidgetsChannel.kinds)

enum HomeWidgetKind {
  static let nextDelivery = "next_delivery"
  static let routeDay = "route_day"
  static let pickingPending = "picking_pending"
  static let storeReceptions = "store_receptions"
  static let supervisorSummary = "supervisor_summary"
  static let quickScan = "quick_scan"
}

// MARK: - Payload

enum HomeWidgetState: String {
  case ok
  case signedOut
  case notAllowed
  case empty
}

/// Payload que manda Dart (JSON). Lectura tolerante: un campo que falta o viene con
/// otro tipo nunca rompe el widget, solo muestra 0 / vacío.
struct HomeWidgetPayload {
  let raw: [String: Any]

  init(_ raw: [String: Any]) {
    self.raw = raw
  }

  /// Sin datos todavía (la app nunca escribió): se trata como sesión cerrada.
  static let signedOut = HomeWidgetPayload(["state": HomeWidgetState.signedOut.rawValue])

  var state: HomeWidgetState {
    HomeWidgetState(rawValue: string("state") ?? "") ?? .ok
  }

  var updatedAt: Date? {
    guard let ms = double("updatedAt"), ms > 0 else { return nil }
    return Date(timeIntervalSince1970: ms / 1000)
  }

  /// Ruta de go_router a la que lleva el toque (ej. "/driver/active").
  var route: String? {
    guard let value = string("route"), value.hasPrefix("/") else { return nil }
    return value
  }

  func string(_ key: String) -> String? {
    switch raw[key] {
    case let value as String: return value
    case let value as NSNumber: return value.stringValue
    default: return nil
    }
  }

  func double(_ key: String) -> Double? {
    switch raw[key] {
    case let value as NSNumber: return value.doubleValue
    case let value as String: return Double(value)
    default: return nil
    }
  }

  func int(_ key: String) -> Int {
    guard let value = double(key), value.isFinite else { return 0 }
    return Int(value)
  }

  /// Progreso acotado a 0…1.
  func progress(_ key: String = "progress") -> Double {
    guard let value = double(key), value.isFinite else { return 0 }
    return min(max(value, 0), 1)
  }
}

// MARK: - Lector del App Group

enum WidgetStore {
  /// Debe coincidir con WidgetsChannel.appGroup y con ambos .entitlements.
  static let appGroup = "group.bo.com.dismac.logisticsApp"

  static func load(kind: String) -> HomeWidgetPayload {
    guard let defaults = UserDefaults(suiteName: appGroup),
      let data = defaults.data(forKey: "widget.\(kind)"),
      let object = try? JSONSerialization.jsonObject(with: data),
      let map = object as? [String: Any]
    else { return .signedOut }
    return HomeWidgetPayload(map)
  }
}

// MARK: - Timeline

struct HomeWidgetEntry: TimelineEntry {
  let date: Date
  let payload: HomeWidgetPayload
}

/// Proveedor común: una sola entrada y policy .never. El widget NO se refresca solo
/// (cuida la batería); se recarga cuando la app manda datos nuevos
/// (WidgetCenter.reloadTimelines desde WidgetsChannel).
struct HomeWidgetProvider: TimelineProvider {
  let kind: String
  /// Datos de muestra para la galería y el placeholder.
  let sample: [String: Any]

  func placeholder(in context: Context) -> HomeWidgetEntry {
    HomeWidgetEntry(date: Date(), payload: HomeWidgetPayload(sample))
  }

  func getSnapshot(in context: Context, completion: @escaping (HomeWidgetEntry) -> Void) {
    // En la galería se muestra la muestra; si no, lo real.
    let payload = context.isPreview ? HomeWidgetPayload(sample) : WidgetStore.load(kind: kind)
    completion(HomeWidgetEntry(date: Date(), payload: payload))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HomeWidgetEntry>) -> Void) {
    let entry = HomeWidgetEntry(date: Date(), payload: WidgetStore.load(kind: kind))
    completion(Timeline(entries: [entry], policy: .never))
  }
}

// MARK: - Deep links (esquema distrack://, lo resuelve WidgetsChannel.handle(url:))

enum WidgetLink {
  /// Caracteres que pueden ir sin escapar en el valor de "route" (se escapan ?, &, =, +, #).
  private static let routeAllowed: CharacterSet = {
    var set = CharacterSet.urlQueryAllowed
    set.remove(charactersIn: "?&=+#")
    return set
  }()

  /// distrack://open?route=<ruta>. Sin ruta: solo abre la app.
  static func open(_ route: String?) -> URL {
    guard let route = route, route.hasPrefix("/"),
      let encoded = route.addingPercentEncoding(withAllowedCharacters: routeAllowed),
      let url = URL(string: "distrack://open?route=\(encoded)")
    else { return URL(string: "distrack://open")! }
    return url
  }

  /// distrack://navigate?daddr=lat,lng (la app abre Apple Maps). nil sin coordenadas.
  static func navigate(lat: Double?, lng: Double?) -> URL? {
    guard let lat = lat, let lng = lng, lat.isFinite, lng.isFinite,
      !(lat == 0 && lng == 0)
    else { return nil }
    return URL(string: "distrack://navigate?daddr=\(lat),\(lng)")
  }
}

// MARK: - Estilos

/// Colores de marca DisTrack (mismos que la Live Activity).
enum HomeBrand {
  static let red = Color(red: 0xE3 / 255, green: 0x06 / 255, blue: 0x13 / 255)
  static let ink = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x14 / 255)
  static let amber = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x00 / 255)
  static let paper = Color(red: 0xF3 / 255, green: 0xF3 / 255, blue: 0xF1 / 255)
  static let green = Color(red: 0x2E / 255, green: 0xB8 / 255, blue: 0x5C / 255)
  static let muted = paper.opacity(0.65)
}

extension View {
  /// Fondo del widget: containerBackground en iOS 17+ (obligatorio, si no iOS 17 muestra
  /// "Please adopt containerBackground API"); fondo común en 16.x.
  @ViewBuilder
  func homeWidgetBackground<Background: View>(
    @ViewBuilder _ background: () -> Background
  ) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget, content: background)
    } else {
      self.background(background())
    }
  }

  /// Fondo de marca para systemSmall / systemMedium. En iOS 17+ el sistema pone los
  /// márgenes (contentMargins); en 16.x hay que poner el padding a mano.
  @ViewBuilder
  func brandWidgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { HomeBrand.ink }
    } else {
      padding().background(HomeBrand.ink)
    }
  }
}

/// Encabezado: ícono rojo + título corto.
struct WidgetHeader: View {
  let symbol: String
  let title: String

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: symbol)
        .font(.caption.weight(.bold))
        .foregroundColor(HomeBrand.red)
      Text(title)
        .font(.caption.weight(.bold))
        .foregroundColor(HomeBrand.paper)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
  }
}

/// Pie "Actualizado HH:mm".
struct WidgetFooter: View {
  let updatedAt: Date?

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "es_BO")
    formatter.dateFormat = "HH:mm"
    return formatter
  }()

  var body: some View {
    if let date = updatedAt {
      Text("Actualizado \(Self.formatter.string(from: date))")
        .font(.caption2)
        .foregroundColor(HomeBrand.muted)
        .lineLimit(1)
    }
  }
}

/// Barra de progreso de marca (más gruesa que ProgressView: se lee bajo el sol).
struct BrandProgressBar: View {
  let value: Double
  var color: Color = HomeBrand.red

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(HomeBrand.paper.opacity(0.18))
        Capsule()
          .fill(color)
          .frame(width: proxy.size.width * CGFloat(min(max(value, 0), 1)))
      }
    }
    .frame(height: 6)
  }
}

/// Número grande + etiqueta (tarjetas de conteo).
struct StatView: View {
  let value: Int
  let label: String
  var color: Color = HomeBrand.paper
  var valueFont: Font = .title.weight(.heavy)

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("\(value)")
        .font(valueFont)
        .foregroundColor(color)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      Text(label)
        .font(.caption2.weight(.semibold))
        .foregroundColor(HomeBrand.muted)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
  }
}

/// Botón visual (en small todo el widget es el toque; en medium va dentro de un Link).
struct WidgetPillButton: View {
  let symbol: String
  let title: String
  var color: Color = HomeBrand.red

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: symbol)
      Text(title).lineLimit(1)
    }
    .font(.subheadline.weight(.bold))
    .foregroundColor(.white)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
    .background(Capsule().fill(color))
  }
}

/// Mensaje de estado (sesión cerrada / rol no permitido / vacío) para small y medium.
struct WidgetStateMessage: View {
  let symbol: String
  let title: String
  let state: HomeWidgetState
  let emptyText: String
  let updatedAt: Date?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      WidgetHeader(symbol: symbol, title: title)
      Spacer(minLength: 0)
      Text(Self.message(state: state, emptyText: emptyText))
        .font(.subheadline.weight(.semibold))
        .foregroundColor(HomeBrand.paper)
        .lineLimit(3)
        .minimumScaleFactor(0.8)
      Spacer(minLength: 0)
      if state == .empty {
        WidgetFooter(updatedAt: updatedAt)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  static func message(state: HomeWidgetState, emptyText: String) -> String {
    switch state {
    case .signedOut: return "Iniciá sesión en DisTrack"
    case .notAllowed: return "No disponible para tu rol"
    case .empty, .ok: return emptyText
    }
  }

  /// Versión corta para la pantalla bloqueada.
  static func shortMessage(state: HomeWidgetState, emptyText: String) -> String {
    switch state {
    case .signedOut: return "Iniciá sesión"
    case .notAllowed: return "No disponible"
    case .empty, .ok: return emptyText
    }
  }
}
