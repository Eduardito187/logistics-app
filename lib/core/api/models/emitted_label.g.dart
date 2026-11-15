// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emitted_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmittedLabel _$EmittedLabelFromJson(Map<String, dynamic> json) => EmittedLabel(
  orderNumber: json['order_number'] as String,
  labelId: json['label_id'] as String,
  keyId: (json['key_id'] as num).toInt(),
  sku: json['sku'] as String,
  lineNumber: (json['line_number'] as num).toInt(),
  qrContent: json['qr_content'] as String,
  zpl: json['zpl'] as String,
  emittedAt: (json['emitted_at'] as num).toInt(),
  productName: json['product_name'] as String?,
  imageUrl: json['image_url'] as String?,
  origin: json['origin'] == null
      ? null
      : Origin.fromJson(json['origin'] as Map<String, dynamic>),
  destination: json['destination'] == null
      ? null
      : Destination2.fromJson(json['destination'] as Map<String, dynamic>),
  unitId: json['unit_id'] as String?,
  shipmentId: json['shipment_id'] as String?,
  unit: json['unit'] == null
      ? null
      : Unit.fromJson(json['unit'] as Map<String, dynamic>),
  piece: json['piece'] == null
      ? null
      : Piece.fromJson(json['piece'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EmittedLabelToJson(EmittedLabel instance) =>
    <String, dynamic>{
      'order_number': instance.orderNumber,
      'label_id': instance.labelId,
      'key_id': instance.keyId,
      'sku': instance.sku,
      'line_number': instance.lineNumber,
      'qr_content': instance.qrContent,
      'zpl': instance.zpl,
      'emitted_at': instance.emittedAt,
      'product_name': instance.productName,
      'image_url': instance.imageUrl,
      'origin': instance.origin,
      'destination': instance.destination,
      'unit_id': instance.unitId,
      'shipment_id': instance.shipmentId,
      'unit': instance.unit,
      'piece': instance.piece,
    };
