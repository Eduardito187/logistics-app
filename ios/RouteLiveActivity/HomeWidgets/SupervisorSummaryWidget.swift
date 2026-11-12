import Foundation
import SwiftUI
import WidgetKit

/// Widget "Resumen del día" (supervisor): entregas, incidencias y camiones en ruta.
///
/// Payload: delivered, incidents, trucksOnRoute.
struct SupervisorSummaryWidget: Widget {
  let kind = HomeWidgetKind.supervisorSummary

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: HomeWidgetProvider(kind: kind, sample: SupervisorSummaryWidget.sample)
    ) { entry in
      SupervisorSummaryWidgetView(payload: entry.payload)
    }
    .configurationDisplayName("Resumen del día")
    .description("Entregas, incidencias y camiones en ruta.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }

  static let sample: [String: Any] = [
    "state": "ok", "delivered": 128, "incidents": 3, "trucksOnRoute": 9, "route": "/home",
  ]
}

private struct SupervisorSummaryWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let payload: HomeWidgetPayload

  private let symbol = "chart.bar.fill"
  private let title = "Resumen del día"

  private var incidents: Int { payload.int("incidents") }

  var body: some View {
    Group {
      if payload.state != .ok {
        WidgetStateMessage(
          symbol: symbol, title: title, state: payload.state,
          emptyText: "Todavía no hay movimiento hoy", updatedAt: payload.updatedAt)
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
      row("checkmark.circle.fill", payload.int("delivered"), "Entregas", HomeBrand.green)
      row(
        "exclamationmark.triangle.fill", incidents, "Incidencias",
        incidents > 0 ? HomeBrand.red : HomeBrand.muted)
      row("box.truck.fill", payload.int("trucksOnRoute"), "En ruta", HomeBrand.amber)
      Spacer(minLength: 0)
      WidgetFooter(updatedAt: payload.updatedAt)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func row(_ icon: String, _ value: Int, _ label: String, _ color: Color) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .foregroundColor(color)
        .frame(width: 18)
      Text("\(value)")
        .font(.headline.weight(.heavy))
        .foregroundColor(HomeBrand.paper)
      Text(label)
        .font(.caption)
        .foregroundColor(HomeBrand.muted)
    }
    .lineLimit(1)
    .minimumScaleFactor(0.7)
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 8) {
      WidgetHeader(symbol: symbol, title: title)
      Spacer(minLength: 0)
      HStack(alignment: .top, spacing: 12) {
        StatView(value: payload.int("delivered"), label: "Entregas", color: HomeBrand.green)
        StatView(
          value: incidents, label: "Incidencias",
          color: incidents > 0 ? HomeBrand.red : HomeBrand.paper)
        StatView(value: payload.int("trucksOnRoute"), label: "Camiones en ruta", color: HomeBrand.amber)
        Spacer(minLength: 0)
      }
      Spacer(minLength: 0)
      WidgetFooter(updatedAt: payload.updatedAt)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}
