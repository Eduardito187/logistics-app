import '../../../core/api/export.dart';

/// `true` si la parada es una TIENDA: el camión DEJA el pedido ahí (para que el
/// cliente lo retire después, `store_pickup`, o como traslado de stock,
/// `transfer`). En ese caso el chofer no entrega a un cliente: solo escanea y
/// saca una foto ("Entregar en tienda"). Con un backend que aún no manda
/// `delivery_mode` devuelve `false` (entrega a domicilio, como siempre).
bool isStoreStop(DriverRouteStop stop) =>
    stop.deliveryMode == DeliveryMode.storePickup ||
    stop.deliveryMode == DeliveryMode.transfer;

/// Nombre a mostrar de la tienda de la parada.
String storeStopName(DriverRouteStop stop) =>
    stop.destinationNodeName ?? stop.customerName ?? 'la tienda';
