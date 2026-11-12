import Foundation
import SwiftUI
import WidgetKit

/// Widget "Mi ruta de hoy" (chofer): entregadas / total con barra y conteos de
/// pendientes y fallidas.
///
/// Payload: delivered, pending, failed, total.
struct RouteDayWidget: Widget {
  let kind = HomeWidgetKind.routeDay

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: HomeWidgetProvider(kind: kind, sample: RouteDayWidget.sample)
    ) { entry in
      RouteDayWidgetView(payload: entry.payload)
    }
    .configurationDisplayName("Mi ruta de hoy")
    .description("Entregas hechas, pendientes y fallidas del día.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }

  static let sample: [String: Any] = [
    "state": "ok", "delivered": 4, "pending": 3, "failed": 1, "total": 8, "route": "/home",
  ]
}

private struct RouteDayWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let payload: HomeWidgetPayload

  private let symbol = "map.fill"
  private let title = "Mi ruta de hoy"

  private var delivered: Int { payload.int("delivered") }
  private var pending: Int { payload.int("pending") }
  private var failed: Int { payload.int("failed") }
  private var total: Int { max(payload.int("total"), delivered + pending + failed) }
  private var progress: Double { total > 0 ? Double(delivered + failed) / Double(total) : 0 }

  var body: some View {
    Group {
      if payload.state != .ok {
        WidgetStateMessage(
          symbol: symbol, title: title, state: payload.state,
          emptyText: "Hoy no tenés ruta asignada", updatedAt: payload.updatedAt)
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
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text("\(delivered)")
          .font(.system(size: 34, weight: .heavy))
          .foregroundColor(HomeBrand.paper)
        Text("/\(total)")
          .font(.title3.weight(.bold))
          .foregroundColor(HomeBrand.muted)
      }
      .lineLimit(1)
      .minimumScaleFactor(0.6)
      Text("entregadas")
        .font(.caption.weight(.semibold))
        .foregroundColor(HomeBrand.muted)
      BrandProgressBar(value: progress)
      HStack(spacing: 8) {
        Label("\(pending)", systemImage: "clock.fill")
          .foregroundColor(HomeBrand.amber)
        Label("\(failed)", systemImage: "xmark.circle.fill")
          .foregroundColor(HomeBrand.red)
      }
      .font(.caption.weight(.bold))
      .labelStyle(.titleAndIcon)
      WidgetFooter(updatedAt: payload.updatedAt)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        WidgetHeader(symbol: symbol, title: title)
        Spacer(minLength: 0)
        Text("\(delivered + failed)/\(total)")
          .font(.caption.weight(.bold))
          .foregroundColor(HomeBrand.muted)
      }
      Spacer(minLength: 0)
      HStack(alignment: .top, spacing: 12) {
        StatView(value: delivered, label: "Entregadas", color: HomeBrand.green)
        StatView(value: pending, label: "Pendientes", color: HomeBrand.amber)
        StatView(value: failed, label: "Fallidas", color: HomeBrand.red)
      }
      BrandProgressBar(value: progress)
      WidgetFooter(updatedAt: payload.updatedAt)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}
