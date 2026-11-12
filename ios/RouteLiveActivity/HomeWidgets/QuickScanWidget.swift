import Foundation
import SwiftUI
import WidgetKit

/// Widget "Escanear" (atajo): un botón grande que abre el escáner del rol. También en
/// la pantalla bloqueada (círculo, iOS 16+).
///
/// Payload: solo state/updatedAt/route (route = pantalla de escaneo del rol).
struct QuickScanWidget: Widget {
  let kind = HomeWidgetKind.quickScan

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: HomeWidgetProvider(kind: kind, sample: QuickScanWidget.sample)
    ) { entry in
      QuickScanWidgetView(payload: entry.payload)
    }
    .configurationDisplayName("Escanear")
    .description("Abre el escáner de DisTrack con un toque.")
    .supportedFamilies([.systemSmall, .accessoryCircular])
  }

  static let sample: [String: Any] = ["state": "ok", "route": "/home"]
}

private struct QuickScanWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let payload: HomeWidgetPayload

  private let symbol = "qrcode.viewfinder"

  var body: some View {
    content
      .widgetURL(WidgetLink.open(payload.state == .ok ? payload.route : nil))
  }

  @ViewBuilder
  private var content: some View {
    if family == .accessoryCircular {
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: symbol)
          .font(.title2.weight(.semibold))
          .widgetAccentable()
      }
      .homeWidgetBackground { Color.clear }
    } else {
      small.brandWidgetBackground()
    }
  }

  /// SOLO el ícono, grande y centrado (pedido del dueño: más simple y
  /// entendible). Sin sesión se ve atenuado y abre la app en el login; el
  /// texto queda para VoiceOver.
  private var small: some View {
    let signedIn = payload.state == .ok || payload.state == .empty
    return ZStack {
      Circle().fill(HomeBrand.red)
      Image(systemName: symbol)
        .font(.system(size: 52, weight: .bold))
        .foregroundColor(.white)
    }
    .padding(14)
    .opacity(signedIn ? 1 : 0.45)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(signedIn ? "Escanear" : "Iniciá sesión en DisTrack")
  }
}
