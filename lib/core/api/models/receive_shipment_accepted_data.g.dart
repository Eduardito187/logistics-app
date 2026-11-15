// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receive_shipment_accepted_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiveShipmentAcceptedData _$ReceiveShipmentAcceptedDataFromJson(
  Map<String, dynamic> json,
) => ReceiveShipmentAcceptedData(
  source: OrderSource.fromJson(json['source'] as String),
  externalId: json['external_id'] as String,
  status: ReceiveShipmentAcceptedDataStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$ReceiveShipmentAcceptedDataToJson(
  ReceiveShipmentAcceptedData instance,
) => <String, dynamic>{
  'source': instance.source,
  'external_id': instance.externalId,
  'status': instance.status,
};
