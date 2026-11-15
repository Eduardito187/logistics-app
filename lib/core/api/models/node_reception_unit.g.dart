// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_reception_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeReceptionUnit _$NodeReceptionUnitFromJson(Map<String, dynamic> json) =>
    NodeReceptionUnit(
      unitId: json['unit_id'] as String,
      sku: json['sku'] as String?,
      productName: json['product_name'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      unitIndex: (json['unit_index'] as num?)?.toInt(),
      unitTotal: (json['unit_total'] as num?)?.toInt(),
      pieceIndex: (json['piece_index'] as num?)?.toInt(),
      pieceTotal: (json['piece_total'] as num?)?.toInt(),
      location: json['location'] as String?,
      locatedAt: json['located_at'] == null
          ? null
          : DateTime.parse(json['located_at'] as String),
    );

Map<String, dynamic> _$NodeReceptionUnitToJson(NodeReceptionUnit instance) =>
    <String, dynamic>{
      'location': instance.location,
      'located_at': instance.locatedAt?.toIso8601String(),
      'unit_id': instance.unitId,
      'sku': instance.sku,
      'product_name': instance.productName,
      'product_image_url': instance.productImageUrl,
      'unit_index': instance.unitIndex,
      'unit_total': instance.unitTotal,
      'piece_index': instance.pieceIndex,
      'piece_total': instance.pieceTotal,
    };
