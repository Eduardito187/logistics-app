import Foundation
import SwiftUI
import WidgetKit

/// Widget "Próxima entrega" (chofer): parada N/M, ETA, progreso de la ruta; en medium
/// además cliente, dirección y botón Navegar. En la pantalla bloqueada (iOS 16+):
/// rectangular "3/7 · 08:15" y circular con Gauge de progreso.
///
/// Payload: stopIndex, stopCount, customer, etaText, progress (0..1), address, lat, lng.
struct NextDeliveryWidget: Widget {
  let kind = HomeWidgetKind.nextDelivery

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: HomeWidgetProvider(kind: kind, sample: NextDeliveryWidget.sample)
    ) { entry in
      NextDeliveryWidgetView(payload: entry.payload)
    }
    .configurationDisplayName("Próxima entrega")
    .description("Tu próxima parada, la hora estimada y el avance de la ruta.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
  }

  static let sample: [String: Any] = [
    "state": "ok",
    "stopIndex": 3,
    "stopCount": 7,
    "customer": "Juan Pérez",
    "etaText": "08:15",
    "progress": 0.43,
    "address": "Av. Cristo Redentor, 4to anillo",
    "lat": -17.7634,
    "lng": -63.1821,
    "route": "/home",
  ]
}

private struct NextDeliveryWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let payload: HomeWidgetPayload

  private let symbol = "box.truck.fill"
  private let title = "Próxima entrega"
  private let emptyText = "Sin entregas pendientes por ahora"

  private var counter: String {
    "\(payload.int("stopIndex"))/\(payload.int("stopCount"))"
  }

  private var eta: String {
    let text = payload.string("etaText") ?? ""
    return text.isEmpty ? "--:--" : text
  }

  var body: some View {
    content
      .widgetURL(WidgetLink.open(payload.route))
  }

  @ViewBuilder
  private var content: some View {
    switch family {
    case .accessoryRectangular:
      rectangular.homeWidgetBackground { Color.clear }
    case .accessoryCircular:
      circular.homeWidgetBackground { AccessoryWidgetBackground() }
    case .systemMedium:
      Group {
        if payload.state == .ok { medium } else { stateMessage }
      }
      .brandWidgetBackground()
    default:
      Group {
        if payload.state == .ok { small } else { stateMessage }
      }
      .brandWidgetBackground()
    }
  }

  private var stateMessage: some View {
    WidgetStateMessage(
      symbol: symbol, title: title, state: payload.state,
      emptyText: emptyText, updatedAt: payload.updatedAt)
  }

  // MARK: systemSmall

  private var small: some View {
    VStack(alignment: .leading, spacing: 4) {
      WidgetHeader(symbol: symbol, title: title)
      Spacer(minLength: 0)
      Text(counter)
        .font(.system(size: 34, weight: .heavy))
        .foregroundColor(HomeBrand.paper)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      HStack(spacing: 4) {
        Image(systemName: "clock.fill")
        Text("Llega \(eta)")
      }
      .font(.subheadline.weight(.bold))
      .foregroundColor(HomeBrand.amber)
      .lineLimit(1)
      BrandProgressBar(value: payload.progress())
      WidgetFooter(updatedAt: payload.updatedAt)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  // MARK: systemMedium

  private var medium: some View {
    HStack(alignment: .top, spacing: 14) {
      small
        .frame(maxWidth: 120)
      VStack(alignment: .leading, spacing: 4) {
        Text(payload.string("customer") ?? "")
          .font(.headline)
          .foregroundColor(HomeBrand.paper)
          .lineLimit(1)
        Text(payload.string("address") ?? "")
          .font(.caption)
          .foregroundColor(HomeBrand.muted)
          .lineLimit(2)
        Spacer(minLength: 0)
        if let url = WidgetLink.navigate(lat: payload.double("lat"), lng: payload.double("lng")) {
          Link(destination: url) {
            WidgetPillButton(symbol: "location.fill", title: "Navegar")
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
  }

  // MARK: Pantalla bloqueada

  private var rectangular: some View {
    VStack(alignment: .leading, spacing: 2) {
      if payload.state == .ok {
        HStack(spacing: 4) {
          Image(systemName: symbol)
          Text("\(counter) · \(eta)")
            .font(.headline)
            .lineLimit(1)
        }
        .widgetAccentable()
        Text(payload.string("customer") ?? "")
          .font(.caption)
          .lineLimit(1)
        ProgressView(value: payload.progress())
      } else {
        HStack(spacing: 4) {
          Image(systemName: symbol)
          Text("DisTrack").font(.headline)
        }
        .widgetAccentable()
        Text(WidgetStateMessage.shortMessage(state: payload.state, emptyText: "Sin entregas"))
          .font(.caption)
          .lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private var circular: some View {
    if payload.state == .ok {
      Gauge(value: payload.progress()) {
        Image(systemName: symbol)
      } currentValueLabel: {
        Text(counter)
          .minimumScaleFactor(0.5)
      }
      .gaugeStyle(.accessoryCircular)
      .widgetAccentable()
    } else {
      Image(systemName: symbol)
        .font(.title2)
        .widgetAccentable()
    }
  }
}
