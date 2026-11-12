import ActivityKit
import SwiftUI
import WidgetKit

/// Colores de marca DisTrack.
private enum Brand {
  static let red = Color(red: 0xE3 / 255, green: 0x06 / 255, blue: 0x13 / 255)
  static let ink = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x14 / 255)
  static let amber = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x00 / 255)
  static let paper = Color(red: 0xF3 / 255, green: 0xF3 / 255, blue: 0xF1 / 255)
}

/// Live Activity de la ruta: pantalla bloqueada + Dynamic Island.
/// Estado: RouteActivityAttributes.ContentState (lo manda la app desde Dart).
struct RouteLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RouteActivityAttributes.self) { context in
      RouteLockScreenView(state: context.state)
        .activityBackgroundTint(Brand.ink)
        .activitySystemActionForegroundColor(Brand.paper)
    } dynamicIsland: { context in
      let state = context.state
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 6) {
            Image(systemName: "box.truck.fill")
              .foregroundColor(Brand.red)
            Text(counter(state))
              .font(.title3.weight(.heavy))
              .foregroundColor(Brand.paper)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          EtaText(state: state)
            .font(.title3.weight(.heavy))
            .foregroundColor(Brand.amber)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(state.customer.isEmpty ? state.title : state.customer)
            .font(.headline)
            .lineLimit(1)
            .foregroundColor(Brand.paper)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: clamped(state.progress))
              .tint(Brand.red)
            HStack {
              Text(statusText(state))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(statusColor(state))
              Spacer()
              if let remaining = state.remainingText, state.status == "on_the_way" {
                Text("A \(remaining)")
                  .font(.subheadline)
                  .foregroundColor(Brand.paper.opacity(0.8))
              }
            }
          }
        }
      } compactLeading: {
        HStack(spacing: 3) {
          Image(systemName: "box.truck.fill")
            .foregroundColor(Brand.red)
          Text(counter(state))
            .font(.caption.weight(.heavy))
        }
      } compactTrailing: {
        Text(state.chip)
          .font(.caption.weight(.heavy))
          .foregroundColor(Brand.amber)
      } minimal: {
        Text(counter(state))
          .font(.caption2.weight(.heavy))
          .foregroundColor(Brand.red)
      }
      .keylineTint(Brand.red)
    }
  }
}

/// Pantalla bloqueada (y banner en iPhone sin isla).
private struct RouteLockScreenView: View {
  let state: RouteActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Image(systemName: "box.truck.fill")
          .foregroundColor(Brand.red)
        Text(state.status == "finished" ? "Ruta completada" : "Parada \(counter(state))")
          .font(.headline.weight(.heavy))
          .foregroundColor(Brand.paper)
        Spacer()
        if state.status != "finished" {
          EtaText(state: state)
            .font(.title2.weight(.heavy))
            .foregroundColor(Brand.amber)
        }
      }
      if !state.customer.isEmpty {
        Text(state.customer)
          .font(.title3.weight(.bold))
          .lineLimit(1)
          .foregroundColor(Brand.paper)
      }
      ProgressView(value: clamped(state.progress))
        .tint(Brand.red)
      HStack {
        Text(statusText(state))
          .font(.subheadline.weight(.semibold))
          .foregroundColor(statusColor(state))
        Spacer()
        if let remaining = state.remainingText, state.status == "on_the_way" {
          Text("A \(remaining)")
            .font(.subheadline)
            .foregroundColor(Brand.paper.opacity(0.8))
        }
      }
    }
    .padding(16)
  }
}

/// Hora estimada ("14:20") o "--:--" sin ETA.
private struct EtaText: View {
  let state: RouteActivityAttributes.ContentState

  var body: some View {
    if let eta = state.etaEpoch {
      Text(Date(timeIntervalSince1970: eta), style: .time)
    } else {
      Text("--:--")
    }
  }
}

private func counter(_ state: RouteActivityAttributes.ContentState) -> String {
  "\(state.stopIndex)/\(state.stopCount)"
}

private func clamped(_ value: Double) -> Double {
  min(max(value, 0), 1)
}

private func statusText(_ state: RouteActivityAttributes.ContentState) -> String {
  switch state.status {
  case "arriving": return "Llegaste a destino"
  case "delivering": return "Entregando"
  case "finished": return "Atendiste \(state.stopCount) paradas"
  default: return "En camino · \(state.completed) de \(state.stopCount) atendidas"
  }
}

private func statusColor(_ state: RouteActivityAttributes.ContentState) -> Color {
  switch state.status {
  case "arriving", "delivering", "finished": return Brand.amber
  default: return Brand.paper.opacity(0.85)
  }
}
