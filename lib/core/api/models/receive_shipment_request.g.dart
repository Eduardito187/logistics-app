// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receive_shipment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiveShipmentRequest _$ReceiveShipmentRequestFromJson(
  Map<String, dynamic> json,
) => ReceiveShipmentRequest(
  source: OrderSource.fromJson(json['source'] as String),
  externalId: json['external_id'] as String,
  customerName: json['customer_name'] as String,
  addressText: json['address_text'] as String,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => ReceiveShipmentLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  customerDocumentId: json['customer_document_id'] as String?,
  customerPhone: json['customer_phone'] as String?,
  customerEmail: json['customer_email'] as String?,
  addressReference: json['address_reference'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ReceiveShipmentRequestToJson(
  ReceiveShipmentRequest instance,
) => <String, dynamic>{
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
  'lines': instance.lines,
};
