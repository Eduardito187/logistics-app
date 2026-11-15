// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'address_confidence_level.dart';
import 'delivery_mode.dart';
import 'order_lookup_node_ref.dart';
import 'order_lookup_tracking.dart';
import 'order_source.dart';
import 'shipment_address_parts.dart';
import 'shipment_line.dart';
import 'shipment_progress.dart';
import 'shipment_status.dart';

part 'order_lookup_item.g.dart';

/// Un envío como lo devuelve GET /app/shipments (siempre con `progress`), más los datos de la consulta abierta.
@JsonSerializable()
class OrderLookupItem {
  const OrderLookupItem({
    required this.id,
    required this.source,
    required this.externalId,
    required this.customerName,
    required this.addressText,
    required this.addressConfidenceScore,
    required this.addressConfidenceLevel,
    required this.status,
    required this.lines,
    required this.orderReference,
    required this.destinationNode,
    required this.tracking,
    required this.canProcess,
    this.progress,
    this.deliveryMode,
    this.addressParts,
    this.shortAddress,
    this.customerDocumentId,
    this.customerPhone,
    this.customerEmail,
    this.addressReference,
    this.lat,
    this.lng,
    this.destinationNodeId,
  });

  factory OrderLookupItem.fromJson(Map<String, Object?> json) =>
      _$OrderLookupItemFromJson(json);

  final ShipmentProgress? progress;
  @JsonKey(name: 'delivery_mode')
  final DeliveryMode? deliveryMode;
  @JsonKey(name: 'address_parts')
  final ShipmentAddressParts? addressParts;

  /// Street + number plus neighborhood or city, at most 80 chars, never empty.
  @JsonKey(name: 'short_address')
  final String? shortAddress;
  final String id;
  final OrderSource source;
  @JsonKey(name: 'external_id')
  final String externalId;
  @JsonKey(name: 'customer_name')
  final String customerName;

  /// Customer identity document (CI / NIT)
  @JsonKey(name: 'customer_document_id')
  final String? customerDocumentId;
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;
  @JsonKey(name: 'customer_email')
  final String? customerEmail;
  @JsonKey(name: 'address_text')
  final String addressText;
  @JsonKey(name: 'address_reference')
  final String? addressReference;
  final double? lat;
  final double? lng;
  @JsonKey(name: 'address_confidence_score')
  final int addressConfidenceScore;
  @JsonKey(name: 'address_confidence_level')
  final AddressConfidenceLevel addressConfidenceLevel;
  final ShipmentStatus status;

  /// UUID del nodo destino del envío (network_nodes). Null mientras el ingest/SAP no lo pueble.
  @JsonKey(name: 'destination_node_id')
  final String? destinationNodeId;
  final List<ShipmentLine> lines;

  /// Referencia del pedido, compartida por los envíos del mismo pedido.
  @JsonKey(name: 'order_reference')
  final String? orderReference;

  /// Nodo destino con su nombre; null en entrega a domicilio sin nodo.
  @JsonKey(name: 'destination_node')
  final OrderLookupNodeRef? destinationNode;
  final OrderLookupTracking tracking;

  /// Si quien consulta podría operar este envío con su rol y asignación actual (preparador, supervisor y admin: siempre; tienda: su nodo es el destino; chofer: el envío está en una ruta suya abierta; transportista: está en un viaje suyo). false = solo consulta.
  @JsonKey(name: 'can_process')
  final bool canProcess;

  Map<String, Object?> toJson() => _$OrderLookupItemToJson(this);
}
