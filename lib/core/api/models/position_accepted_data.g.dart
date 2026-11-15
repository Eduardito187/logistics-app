// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_accepted_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionAcceptedData _$PositionAcceptedDataFromJson(
  Map<String, dynamic> json,
) => PositionAcceptedData(
  shipmentId: json['shipment_id'] as String,
  accepted: json['accepted'] as bool,
);

Map<String, dynamic> _$PositionAcceptedDataToJson(
  PositionAcceptedData instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'accepted': instance.accepted,
};
