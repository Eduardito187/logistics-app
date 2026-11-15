// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'failed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Failed _$FailedFromJson(Map<String, dynamic> json) => Failed(
  shipmentId: json['shipment_id'] as String?,
  externalId: json['external_id'] as String?,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$FailedToJson(Failed instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'external_id': instance.externalId,
  'reason': instance.reason,
};
