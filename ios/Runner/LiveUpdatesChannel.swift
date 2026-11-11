import Flutter
import Foundation

#if canImport(ActivityKit)
  import ActivityKit
#endif

/// Ruta del chofer en vivo como Live Activity (pantalla bloqueada + Dynamic
/// Island). Contraparte Dart: lib/core/live_updates/.
///
/// - "isSupported" → {android: {promoted: false, sdk: 0}, ios: {liveActivities: Bool}}
/// - "start" / "update" (mapa de RouteLiveStatus.toMap) → Bool
/// - "end" (mapa opcional con el estado final) → Bool
///
/// iOS solo deja PEDIR una Live Activity con la app en primer plano (Dart la
/// pide apenas hay ruta activa); los updates sí funcionan en segundo plano
/// mientras el rastreo GPS mantiene viva la app. Sin iOS 16.1 o con las Live
/// Activities apagadas por el usuario, todo devuelve false (no-op).
///
/// Además registra ScreenChannel (brillo al mostrar un QR) para no tocar
/// AppDelegate.
enum LiveUpdatesChannel {
  private static let channelName = "bo.com.dismac/live_updates"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isSupported":
        result([
          "android": ["promoted": false, "sdk": 0],
          "ios": ["liveActivities": liveActivitiesEnabled()],
        ])
      case "start", "update":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Falta el estado de la ruta", details: nil))
          return
        }
        #if canImport(ActivityKit)
          if #available(iOS 16.1, *) {
            Task { @MainActor in
              result(await startOrUpdate(args))
            }
            return
          }
        #endif
        result(false)
      case "end":
        #if canImport(ActivityKit)
          if #available(iOS 16.1, *) {
            let args = call.arguments as? [String: Any]
            Task { @MainActor in
              await endAll(args)
              result(true)
            }
            return
          }
        #endif
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    ScreenChannel.register(messenger: messenger)
  }

  private static func liveActivitiesEnabled() -> Bool {
    #if canImport(ActivityKit)
      if #available(iOS 16.1, *) {
        return ActivityAuthorizationInfo().areActivitiesEnabled
      }
    #endif
    return false
  }

  #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private static func state(from args: [String: Any]) -> RouteActivityAttributes.ContentState {
      let etaMs = (args["etaEpochMs"] as? NSNumber)?.doubleValue
      return RouteActivityAttributes.ContentState(
        stopIndex: (args["stopIndex"] as? NSNumber)?.intValue ?? 0,
        stopCount: (args["stopCount"] as? NSNumber)?.intValue ?? 0,
        completed: (args["completed"] as? NSNumber)?.intValue ?? 0,
        customer: args["customer"] as? String ?? "",
        etaEpoch: etaMs.map { $0 / 1000 },
        progress: (args["progress"] as? NSNumber)?.doubleValue ?? 0,
        status: args["status"] as? String ?? "on_the_way",
        title: args["title"] as? String ?? "Ruta en curso",
        chip: args["chip"] as? String ?? "",
        remainingText: args["remainingText"] as? String
      )
    }

    /// Actualiza la actividad de la misma ruta si existe; si no, la pide.
    @available(iOS 16.1, *)
    @MainActor
    private static func startOrUpdate(_ args: [String: Any]) async -> Bool {
      guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
      let routeId = args["routeId"] as? String ?? ""
      let newState = state(from: args)
      let activities = Activity<RouteActivityAttributes>.activities
      if let current = activities.first(where: { $0.attributes.routeId == routeId }) {
        // Cualquier otra (ruta vieja) se cierra.
        for other in activities where other.id != current.id {
          await end(other, state: nil, immediate: true)
        }
        if #available(iOS 16.2, *) {
          await current.update(ActivityContent(state: newState, staleDate: nil))
        } else {
          await current.update(using: newState)
        }
        return true
      }
      for other in activities {
        await end(other, state: nil, immediate: true)
      }
      do {
        let attributes = RouteActivityAttributes(routeId: routeId)
        if #available(iOS 16.2, *) {
          _ = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: newState, staleDate: nil),
            pushType: nil
          )
        } else {
          _ = try Activity.request(
            attributes: attributes,
            contentState: newState,
            pushType: nil
          )
        }
        return true
      } catch {
        // App en segundo plano, límite de actividades o apagadas: no-op.
        return false
      }
    }

    /// Cierra todas; con el estado final ("Ruta completada") lo deja unos
    /// minutos en la pantalla bloqueada.
    @available(iOS 16.1, *)
    @MainActor
    private static func endAll(_ args: [String: Any]?) async {
      let finalState = args.map { state(from: $0) }
      for activity in Activity<RouteActivityAttributes>.activities {
        await end(activity, state: finalState, immediate: finalState == nil)
      }
    }

    @available(iOS 16.1, *)
    private static func end(
      _ activity: Activity<RouteActivityAttributes>,
      state: RouteActivityAttributes.ContentState?,
      immediate: Bool
    ) async {
      let policy: ActivityUIDismissalPolicy =
        immediate ? .immediate : .after(Date().addingTimeInterval(5 * 60))
      if #available(iOS 16.2, *) {
        let content = state.map { ActivityContent(state: $0, staleDate: nil) }
        await activity.end(content, dismissalPolicy: policy)
      } else {
        await activity.end(using: state, dismissalPolicy: policy)
      }
    }
  #endif
}
