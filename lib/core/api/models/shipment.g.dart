// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Shipment _$ShipmentFromJson(Map<String, dynamic> json) => Shipment(
  id: json['id'] as String,
  source: OrderSource.fromJson(json['source'] as String),
  externalId: json['external_id'] as String,
  customerName: json['customer_name'] as String,
  addressText: json['address_text'] as String,
  addressConfidenceScore: (json['address_confidence_score'] as num).toInt(),
  addressConfidenceLevel: AddressConfidenceLevel.fromJson(
    json['address_confidence_level'] as String,
  ),
  status: ShipmentStatus.fromJson(json['status'] as String),
  lines: (json['lines'] as List<dynamic>)
      .map((e) => ShipmentLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  progress: json['progress'] == null
      ? null
      : ShipmentProgress.fromJson(json['progress'] as Map<String, dynamic>),
  deliveryMode: json['delivery_mode'] == null
      ? null
      : DeliveryMode.fromJson(json['delivery_mode'] as String),
  addressParts: json['address_parts'] == null
      ? null
      : ShipmentAddressParts.fromJson(
          json['address_parts'] as Map<String, dynamic>,
        ),
  shortAddress: json['short_address'] as String?,
  customerDocumentId: json['customer_document_id'] as String?,
  customerPhone: json['customer_phone'] as String?,
  customerEmail: json['customer_email'] as String?,
  addressReference: json['address_reference'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  destinationNodeId: json['destination_node_id'] as String?,
);

Map<String, dynamic> _$ShipmentToJson(Shipment instance) => <String, dynamic>{
  'progress': instance.progress,
  'delivery_mode': instance.deliveryMode,
  'address_parts': instance.addressParts,
  'short_address': instance.shortAddress,
  'id': instance.id,
  'source': instance.source,
  'external_id': instance.externalId,
  'customer_name': instance.customerName,
  'customer_document_id': instance.customerDocumentId,
  'customer_phone': instance.customerPhone,
  'customer_email': instance.customerEmail,
  'address_text': instance.addressText,
  'address_reference': instance.addressReference,
  'lat': instance.lat,
  'lng': instance.lng,
  'address_confidence_score': instance.addressConfidenceScore,
  'address_confidence_level': instance.addressConfidenceLevel,
  'status': instance.status,
  'destination_node_id': instance.destinationNodeId,
  'lines': instance.lines,
};
