// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_mode.dart';
import 'destination.dart';
import 'driver_route_stop_arrival_source.dart';
import 'driver_route_stop_status.dart';
import 'items3.dart';

part 'driver_route_stop.g.dart';

/// A stop of the driver route — what the driver drops at one point
@JsonSerializable()
class DriverRouteStop {
  const DriverRouteStop({
    required this.id,
    required this.shipmentId,
    required this.sequence,
    required this.items,
    required this.status,
    this.orderReference,
    this.customerName,
    this.customerPhone,
    this.address,
    this.addressReference,
    this.etaAt,
    this.lat,
    this.lng,
    this.settledAt,
    this.arrivedAt,
    this.arrivalSource,
    this.deliveryMode,
    this.destinationNodeId,
    this.destinationNodeName,
    this.unitsTotal,
    this.unitIds,
    this.destination,
    this.podConfirmation,
    this.podPhotoUrl,
  });

  factory DriverRouteStop.fromJson(Map<String, Object?> json) =>
      _$DriverRouteStopFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final int sequence;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;

  /// Customer phone resolved from the shipment (cross-context). Null if unknown.
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;
  final String? address;

  /// Address reference/landmark (gate, floor) resolved from the shipment. Null if unknown.
  @JsonKey(name: 'address_reference')
  final String? addressReference;

  /// Order lines dropped at this stop, resolved from the shipment. Always present (empty when unknown).
  final List<Items3> items;
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;
  final double? lat;
  final double? lng;
  final DriverRouteStopStatus status;
  @JsonKey(name: 'settled_at')
  final DateTime? settledAt;

  /// First reported arrival at the stop (POST /app/deliveries/{shipmentId}/arrived).
  @JsonKey(name: 'arrived_at')
  final DateTime? arrivedAt;
  @JsonKey(name: 'arrival_source')
  final DriverRouteStopArrivalSource? arrivalSource;

  /// Modalidad de la parada. home_delivery = se entrega al cliente (POD con firma). store_pickup / transfer = el chofer NO entrega al cliente: deja el pedido en la tienda con POST /app/deliveries/{shipmentId}/store-drop.
  @JsonKey(name: 'delivery_mode')
  final DeliveryMode? deliveryMode;

  /// Tienda/nodo destino de la parada; null si es a domicilio.
  @JsonKey(name: 'destination_node_id')
  final String? destinationNodeId;
  @JsonKey(name: 'destination_node_name')
  final String? destinationNodeName;

  /// Number of physical products (shipment units) of the stop; the POD expects this many, not the sum of quantities.
  @JsonKey(name: 'units_total')
  final int? unitsTotal;
  @JsonKey(name: 'unit_ids')
  final List<String>? unitIds;

  /// Tipo de destino de la parada, para que la app muestre UNA acción: home → "Entregar" (POD); store/warehouse (hub/tienda/almacén) → "Descargar" (escaneo de descarga). Derivado de shipments.destination_node_id (null = home). Null si no se pudo resolver el envío.
  final Destination? destination;

  /// Confirmación de la prueba de entrega ya capturada para este envío (firma/receptor), misma fuente que GET /app/deliveries/{shipmentId}. Null mientras no haya POD.
  @JsonKey(name: 'pod_confirmation')
  final String? podConfirmation;

  /// URL de la foto del POD si el disco de evidencia la expone (puede ser null en disco privado aunque exista la foto; la referencia durable vive en la entrega).
  @JsonKey(name: 'pod_photo_url')
  final String? podPhotoUrl;

  Map<String, Object?> toJson() => _$DriverRouteStopToJson(this);
}
