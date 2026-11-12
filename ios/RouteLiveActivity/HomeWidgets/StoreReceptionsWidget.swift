import Foundation
import SwiftUI
import WidgetKit

/// Widget "Mi tienda" (tienda): envíos por recibir y pedidos de "Recojo en tienda".
///
/// Payload: incoming, pickups.
struct StoreReceptionsWidget: Widget {
  let kind = HomeWidgetKind.storeReceptions

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: HomeWidgetProvider(kind: kind, sample: StoreReceptionsWidget.sample)
    ) { entry in
      StoreReceptionsWidgetView(payload: entry.payload)
    }
    .configurationDisplayName("Mi tienda")
    .description("Envíos por recibir y pedidos de Recojo en tienda.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }

  static let sample: [String: Any] = [
    "state": "ok", "incoming": 5, "pickups": 3, "route": "/home",
  ]
}

private struct StoreReceptionsWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let payload: HomeWidgetPayload

  private let symbol = "tray.and.arrow.down.fill"
  private let title = "Mi tienda"

  var body: some View {
    Group {
      if payload.state != .ok {
        WidgetStateMessage(
          symbol: symbol, title: title, state: payload.state,
          emptyText: "Sin recepciones ni recojos pendientes", updatedAt: payload.updatedAt)
      } else {
        content
      }
    }
    .brandWidgetBackground()
    .widgetURL(WidgetLink.open(payload.route))
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 6) {
      WidgetHeader(symbol: symbol, title: title)
      Spacer(minLength: 0)
      if family == .systemMedium {
        HStack(alignment: .top, spacing: 18) {
          StatView(
            value: payload.int("incoming"), label: "Por recibir", color: HomeBrand.amber,
            valueFont: .system(size: 34, weight: .heavy))
          StatView(
            value: payload.int("pickups"), label: "Recojo en tienda",
            valueFont: .system(size: 34, weight: .heavy))
          Spacer(minLength: 0)
        }
      } else {
        StatView(value: payload.int("incoming"), label: "Por recibir", color: HomeBrand.amber)
        StatView(value: payload.int("pickups"), label: "Recojo en tienda")
      }
      WidgetFooter(updatedAt: payload.updatedAt)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}
