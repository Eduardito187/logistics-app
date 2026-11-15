import '../../../core/api/export.dart';

/// Etapa de un pedido en palabras que se le pueden leer a un cliente. La etapa
/// la CALCULA el backend (`tracking.stage`): acá solo se traduce. No se deduce
/// en la app: por ejemplo, un pedido con camión asignado ya figura "en
/// ejecución" sin haber salido, y solo el servidor sabe si realmente salió.
String orderStageLabel(OrderLookupStage stage) => switch (stage) {
  OrderLookupStage.received => 'Recibido, todavía sin planificar',
  OrderLookupStage.planned => 'Planificado, todavía no salió',
  OrderLookupStage.prepared => 'Preparado, esperando salir',
  OrderLookupStage.onTheWay => 'En camino',
  OrderLookupStage.atStore => 'En la tienda, listo para retirar',
  OrderLookupStage.delivered => 'Entregado',
  OrderLookupStage.failed => 'No se pudo entregar',
  OrderLookupStage.cancelled => 'Cancelado',
  OrderLookupStage.$unknown => 'Sin información',
};

/// `true` si el pedido ya terminó su recorrido (no va a cambiar).
bool orderStageClosed(OrderLookupStage stage) =>
    stage == OrderLookupStage.delivered ||
    stage == OrderLookupStage.failed ||
    stage == OrderLookupStage.cancelled;

/// "Está a 3 paradas de llegar" / "Es la próxima parada", o `null` si el pedido
/// no está en una ruta (el backend no manda el dato).
String? stopsBeforeText(int? stopsBefore) {
  if (stopsBefore == null) return null;
  if (stopsBefore <= 0) return 'Es la próxima parada del camión';
  return stopsBefore == 1
      ? 'Está a 1 parada de llegar'
      : 'Está a $stopsBefore paradas de llegar';
}

/// Cómo se entrega el pedido, en una línea.
String deliveryModeText(DeliveryMode? mode) => switch (mode) {
  DeliveryMode.storePickup => 'El cliente lo retira en la tienda',
  DeliveryMode.transfer => 'Traslado a tienda',
  DeliveryMode.homeDelivery => 'Entrega a domicilio',
  _ => 'Entrega',
};
