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
  customerDocumentId: json['customer_document_id'] as String?,
  customerPhone: json['customer_phone'] as String?,
  customerEmail: json['customer_email'] as String?,
  addressReference: json['address_reference'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ShipmentToJson(Shipment instance) => <String, dynamic>{
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
  'lines': instance.lines,
};
