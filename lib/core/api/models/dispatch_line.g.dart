// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispatchLine _$DispatchLineFromJson(Map<String, dynamic> json) => DispatchLine(
  sku: json['sku'] as String,
  productName: json['product_name'] as String?,
  imageUrl: json['image_url'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  piecesPerUnit: (json['pieces_per_unit'] as num).toInt(),
  lineNumber: (json['line_number'] as num).toInt(),
  origin: Origin2.fromJson(json['origin'] as Map<String, dynamic>),
  destination: DispatchDestination.fromJson(
    json['destination'] as Map<String, dynamic>,
  ),
  shipmentId: json['shipment_id'] as String?,
  shipmentReference: json['shipment_reference'] as String?,
  authorized: json['authorized'] as bool,
  authorizedReason: json['authorized_reason'] as String?,
  labelStatus: DispatchLineLabelStatus.fromJson(json['label_status'] as String),
);

Map<String, dynamic> _$DispatchLineToJson(DispatchLine instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'product_name': instance.productName,
      'image_url': instance.imageUrl,
      'quantity': instance.quantity,
      'pieces_per_unit': instance.piecesPerUnit,
      'line_number': instance.lineNumber,
      'origin': instance.origin,
      'destination': instance.destination,
      'shipment_id': instance.shipmentId,
      'shipment_reference': instance.shipmentReference,
      'authorized': instance.authorized,
      'authorized_reason': instance.authorizedReason,
      'label_status': instance.labelStatus,
    };
