import Foundation

#if canImport(ActivityKit)
  import ActivityKit

  /// Live Activity de la ruta del chofer (pantalla bloqueada + Dynamic Island).
  ///
  /// IMPORTANTE: este archivo debe pertenecer a DOS targets en Xcode: "Runner"
  /// (la app la pide/actualiza desde LiveUpdatesChannel.swift) y
  /// "RouteLiveActivity" (la extensión la dibuja). Ver docs/live-updates.md.
  ///
  /// Los campos de [ContentState] salen de `RouteLiveStatus.toMap()` (Dart,
  /// lib/core/live_updates/route_live_status.dart).
  @available(iOS 16.1, *)
  struct RouteActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
      /// Parada en curso (1-based) y total.
      var stopIndex: Int
      var stopCount: Int
      /// Paradas atendidas.
      var completed: Int
      /// Cliente / destino corto.
      var customer: String
      /// ETA de la parada en segundos desde 1970 (nil sin hora estimada).
      var etaEpoch: Double?
      /// Avance 0...1.
      var progress: Double
      /// on_the_way | arriving | delivering | finished
      var status: String
      /// Título ya armado en español ("Parada 3 de 8 · Llega 14:20").
      var title: String
      /// Texto cortísimo ("14:20", "3/8", "Llegó").
      var chip: String
      /// "2,3 km" (nil sin GPS).
      var remainingText: String?
    }

    /// Ruta del día (fijo durante la actividad).
    var routeId: String
  }
#endif
