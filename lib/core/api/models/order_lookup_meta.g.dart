// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_lookup_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderLookupMeta _$OrderLookupMetaFromJson(Map<String, dynamic> json) =>
    OrderLookupMeta(
      count: (json['count'] as num).toInt(),
      matchedBy: OrderLookupMatch.fromJson(json['matched_by'] as String),
      matchedShipmentId: json['matched_shipment_id'] as String?,
    );

Map<String, dynamic> _$OrderLookupMetaToJson(OrderLookupMeta instance) =>
    <String, dynamic>{
      'count': instance.count,
      'matched_by': instance.matchedBy,
      'matched_shipment_id': instance.matchedShipmentId,
    };
