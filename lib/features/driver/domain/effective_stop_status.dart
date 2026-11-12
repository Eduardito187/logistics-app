import '../../../core/api/export.dart';

/// Estado a mostrar de [stop]: el del backend, salvo que siga "pendiente" y el
/// chofer ya la haya resuelto en este teléfono (POD o entrega fallida en la cola
/// offline). Criterio ÚNICO de la app: lo usan la lista de paradas, la entrega
/// en curso, la notificación en vivo y las métricas de "Mi día", así que una
/// parada cerrada sin señal nunca aparece pendiente en una pantalla y resuelta
/// en otra.
///
/// Vive en `domain` (es una regla, no estado de UI) y se reexporta desde
/// `presentation/controllers/locally_settled_stops.dart`, que es donde vive el
/// mapa de paradas resueltas localmente.
DriverRouteStopStatus effectiveStopStatus(
  DriverRouteStop stop,
  Map<String, DriverRouteStopStatus> settled,
) => stop.status == DriverRouteStopStatus.pending
    ? settled[stop.id] ?? stop.status
    : stop.status;
