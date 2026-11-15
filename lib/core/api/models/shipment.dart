// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'address_confidence_level.dart';
import 'delivery_mode.dart';
import 'order_lookup_node_ref.dart';
import 'order_source.dart';
import 'shipment_address_parts.dart';
import 'shipment_delivery_evidence.dart';
import 'shipment_line.dart';
import 'shipment_progress.dart';
import 'shipment_status.dart';

part 'shipment.g.dart';

@JsonSerializable()
class Shipment {
  const Shipment({
    required this.id,
    required this.source,
    required this.externalId,
    required this.customerName,
    required this.addressText,
    required this.addressConfidenceScore,
    required this.addressConfidenceLevel,
    required this.status,
    required this.lines,
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
    this.originNode,
    this.originDepartment,
    this.destinationDepartment,
    this.deliveryEvidence,
  });

  factory Shipment.fromJson(Map<String, Object?> json) =>
      _$ShipmentFromJson(json);

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

  /// Nodo del que sale el envío (informado por el origen del pedido o deducido: almacén central del departamento destino). Null mientras no se resuelve.
  @JsonKey(name: 'origin_node')
  final OrderLookupNodeRef? originNode;

  /// Código del departamento del nodo de origen (la_paz, santa_cruz, …); null mientras no se resuelve.
  @JsonKey(name: 'origin_department')
  final String? originDepartment;

  /// Código del departamento del destino (el del nodo destino, o el de la ciudad de entrega a domicilio); null mientras no se resuelve.
  @JsonKey(name: 'destination_department')
  final String? destinationDepartment;

  /// Cómo se entregó: qué evidencia quedó de la entrega. Null si el envío no está entregado. Viene en la lista y en la ficha de /app/shipments.
  @JsonKey(name: 'delivery_evidence')
  final ShipmentDeliveryEvidence? deliveryEvidence;

  Map<String, Object?> toJson() => _$ShipmentToJson(this);
}
