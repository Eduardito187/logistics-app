import Foundation
import SwiftUI
import WidgetKit

/// Widget "Por preparar" (preparador/andén): pedidos pendientes y en curso; en
/// medium, botón "Escanear" que abre directo el escáner.
///
/// Payload: pending, inProgress, scanRoute.
struct PickingPendingWidget: Widget {
  let kind = HomeWidgetKind.pickingPending

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: HomeWidgetProvider(kind: kind, sample: PickingPendingWidget.sample)
    ) { entry in
      PickingPendingWidgetView(payload: entry.payload)
    }
    .configurationDisplayName("Por preparar")
    .description("Pedidos por preparar y en curso, con acceso al escáner.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }

  static let sample: [String: Any] = [
    "state": "ok", "pending": 12, "inProgress": 2, "scanRoute": "/home", "route": "/home",
  ]
}

private struct PickingPendingWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let payload: HomeWidgetPayload

  private let symbol = "shippingbox.fill"
  private let title = "Por preparar"

  var body: some View {
    Group {
      if payload.state != .ok {
        WidgetStateMessage(
          symbol: symbol, title: title, state: payload.state,
          emptyText: "Nada por preparar. ¡Bien hecho!", updatedAt: payload.updatedAt)
      } else if family == .systemMedium {
        medium
      } else {
        small
      }
    }
    .brandWidgetBackground()
    .widgetURL(WidgetLink.open(payload.route))
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 4) {
      WidgetHeader(symbol: symbol, title: title)
      Spacer(minLength: 0)
      StatView(
        value: payload.int("pending"), label: "pedidos pendientes",
        valueFont: .system(size: 34, weight: .heavy))
      Label("\(payload.int("inProgress")) en curso", systemImage: "hourglass")
        .font(.caption.weight(.bold))
        .foregroundColor(HomeBrand.amber)
        .lineLimit(1)
      WidgetFooter(updatedAt: payload.updatedAt)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private var medium: some View {
    HStack(alignment: .center, spacing: 14) {
      small
      VStack {
        Spacer(minLength: 0)
        Link(destination: WidgetLink.open(payload.string("scanRoute") ?? payload.route)) {
          WidgetPillButton(symbol: "barcode.viewfinder", title: "Escanear")
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: 140)
    }
  }
}
