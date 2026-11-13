import 'package:flutter/foundation.dart';

import '../../features/driver/domain/entities/route_navigation.dart';
import 'route_live_state.dart';

/// Foto de la ruta del chofer para la notificación en vivo de la barra de
/// estado (Android 16 Live Updates / chip) y la Live Activity de iOS (pantalla
/// bloqueada + Dynamic Island).
///
/// Los textos visibles se arman ACÁ (en español, probados en Dart) y viajan ya
/// listos al lado nativo, que solo los pinta. El widget de iOS además recibe
/// los números crudos (parada, total, progreso, ETA) para su propio diseño.
@immutable
class RouteLiveStatus {
  const RouteLiveStatus({
    required this.routeId,
    required this.stopId,
    required this.stopIndex,
    required this.stopCount,
    required this.completedCount,
    required this.customer,
    required this.state,
    this.etaAt,
    this.remainingMeters,
    this.lat,
    this.lng,
  });

  /// Largo máximo del nombre del cliente en la notificación (una línea).
  static const int maxCustomerLength = 32;

  final String routeId;

  /// Id de la parada en curso (vacío cuando la ruta terminó).
  final String stopId;

  /// Número de la parada en curso (1-based, el `sequence` de la ruta).
  final int stopIndex;

  /// Total de paradas de la ruta.
  final int stopCount;

  /// Paradas ya atendidas (entregadas o fallidas, incluidas las resueltas en
  /// este teléfono que el backend aún no sabe).
  final int completedCount;

  /// Cliente o destino, ya acortado a [maxCustomerLength].
  final String customer;

  final RouteLiveState state;

  /// Hora estimada de llegada a la parada (la del backend, la misma que muestra
  /// la tarjeta de "Entrega en curso").
  final DateTime? etaAt;

  /// Distancia restante estimada hasta la parada; `null` sin GPS.
  final double? remainingMeters;

  /// Coordenadas de la parada (acción "Navegar").
  final double? lat;
  final double? lng;

  /// Avance de la ruta, de 0 a 1 (paradas atendidas / total).
  double get progress {
    if (stopCount <= 0) return state == RouteLiveState.finished ? 1 : 0;
    return (completedCount / stopCount).clamp(0.0, 1.0);
  }

  /// "14:20" en hora local, o `null` sin ETA.
  String? get etaText {
    final eta = etaAt;
    if (eta == null) return null;
    final local = eta.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// "2,3 km" / "350 m", o `null` sin distancia.
  String? get remainingText {
    final meters = remainingMeters;
    return meters == null ? null : formatDistance(meters);
  }

  /// "3/8": parada en curso sobre el total.
  String get counterText => '$stopIndex/$stopCount';

  /// Contador de AVANCE para la pastilla/chip de la cámara: "6/7" = paradas
  /// ATENDIDAS / total (`completedCount` = entregadas + fallidas, como la barra
  /// de progreso). Sube al cerrar una parada. Es el avance de la ruta, no sólo
  /// las entregadas (el desglose entregada/fallida vive en "Mi ruta"). Pedido
  /// del dueño: sólo el ícono del camión + la cantidad, SIN la hora.
  String get attendedCounterText => '$completedCount/$stopCount';

  /// Ordinal de ESTA entrega en el avance del día (atendidas + 1): con entregas
  /// fuera de orden, mostrar la SECUENCIA de la parada pendiente (p. ej. 1)
  /// confundía ("Parada 1 de 7" con 6 hechas). Va con el contador de la isla.
  int get deliveryPosition =>
      stopCount == 0 ? 1 : (completedCount + 1).clamp(1, stopCount);

  /// Título de la notificación.
  String get title {
    final stop = 'Parada $deliveryPosition de $stopCount';
    switch (state) {
      case RouteLiveState.onTheWay:
        final eta = etaText;
        return eta == null ? stop : '$stop · Llega $eta';
      case RouteLiveState.arriving:
        return 'Llegaste · $stop';
      case RouteLiveState.delivering:
        return 'Entregando · $stop';
      case RouteLiveState.finished:
        return 'Ruta completada';
    }
  }

  /// Texto de la notificación: a quién se lleva (o el cierre del día).
  String get body {
    if (state == RouteLiveState.finished) {
      return stopCount == 1
          ? 'Atendiste la parada del día.'
          : 'Atendiste las $stopCount paradas del día.';
    }
    return customer;
  }

  /// Línea secundaria: "A 2,3 km" mientras va en camino.
  String? get subText {
    if (state != RouteLiveState.onTheWay) return null;
    final remaining = remainingText;
    return remaining == null ? null : 'A $remaining';
  }

  /// Texto corto del chip de la barra de estado (Android 16) / isla compacta:
  /// SOLO el contador de ENTREGAS ("6/7"), sin la hora (pedido del dueño). El
  /// ícono del camión lo pone el nativo. Al terminar la ruta, "Listo".
  String get chipText =>
      state == RouteLiveState.finished ? 'Listo' : attendedCounterText;

  /// Cambio que se publica al instante (sin esperar el intervalo mínimo):
  /// otra parada, otro estado, otro avance, otro cliente u otra ETA.
  bool majorChangeFrom(RouteLiveStatus other) =>
      routeId != other.routeId ||
      stopId != other.stopId ||
      stopIndex != other.stopIndex ||
      stopCount != other.stopCount ||
      completedCount != other.completedCount ||
      customer != other.customer ||
      state != other.state ||
      etaText != other.etaText;

  /// `true` si se vería IGUAL en la notificación: la distancia se compara ya
  /// redondeada ("2,3 km"), así unos metros de GPS no cuentan como cambio.
  bool sameContentAs(RouteLiveStatus other) =>
      !majorChangeFrom(other) && remainingText == other.remainingText;

  RouteLiveStatus copyWith({RouteLiveState? state}) => RouteLiveStatus(
    routeId: routeId,
    stopId: stopId,
    stopIndex: stopIndex,
    stopCount: stopCount,
    completedCount: completedCount,
    customer: customer,
    state: state ?? this.state,
    etaAt: etaAt,
    remainingMeters: remainingMeters,
    lat: lat,
    lng: lng,
  );

  /// Argumentos del canal `bo.com.dismac/live_updates` ("start"/"update").
  Map<String, Object?> toMap() => {
    'routeId': routeId,
    'stopId': stopId,
    'stopIndex': stopIndex,
    'stopCount': stopCount,
    'completed': completedCount,
    'progress': progress,
    'status': state.wireName,
    'customer': customer,
    'etaEpochMs': etaAt?.millisecondsSinceEpoch,
    'etaText': etaText,
    'remainingMeters': remainingMeters,
    'remainingText': remainingText,
    'lat': lat,
    'lng': lng,
    'title': title,
    'body': body,
    'subText': subText,
    'chip': chipText,
    // Versión para la pantalla bloqueada SIN el nombre del cliente.
    'publicTitle': title,
  };

  /// Acorta [name] a [maxCustomerLength] con "…".
  static String shortCustomer(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= maxCustomerLength) return trimmed;
    return '${trimmed.substring(0, maxCustomerLength - 1).trimRight()}…';
  }
}
