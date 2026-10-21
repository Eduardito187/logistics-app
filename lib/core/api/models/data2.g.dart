// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data2 _$Data2FromJson(Map<String, dynamic> json) => Data2(
  shipmentId: json['shipment_id'] as String,
  type: DeliveryIssueType.fromJson(json['type'] as String),
  status: Status2.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data2ToJson(Data2 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'type': instance.type,
  'status': instance.status,
};
