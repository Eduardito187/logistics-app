import SwiftUI
import WidgetKit

/// Extensión "RouteLiveActivity" (un solo target en Xcode): la Live Activity de la
/// ruta del chofer (pantalla bloqueada + Dynamic Island) y los 6 widgets de inicio
/// (ios/RouteLiveActivity/HomeWidgets/). Mínimo iOS 16.1 (RouteLiveActivity.xcconfig),
/// así que WidgetKit, ActivityKit y las familias de pantalla bloqueada están siempre;
/// solo containerBackground (iOS 17) se protege con #available (ver WidgetData.swift).
///
/// Los widgets leen el App Group "group.bo.com.dismac.logisticsApp" que escribe
/// Runner/WidgetsChannel.swift; la galería muestra los 6 a todos los roles (iOS no
/// permite filtrarla) y cada widget dice "No disponible para tu rol" si no aplica.
@main
struct RouteLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    RouteLiveActivityWidget()
    NextDeliveryWidget()
    RouteDayWidget()
    PickingPendingWidget()
    StoreReceptionsWidget()
    SupervisorSummaryWidget()
    QuickScanWidget()
  }
}
