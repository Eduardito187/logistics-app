// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_sequence_warning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripSequenceWarning _$TripSequenceWarningFromJson(Map<String, dynamic> json) =>
    TripSequenceWarning(
      code: TripSequenceWarningCode.fromJson(json['code'] as String),
      shipmentId: json['shipment_id'] as String,
      detail: json['detail'] as String,
    );

Map<String, dynamic> _$TripSequenceWarningToJson(
  TripSequenceWarning instance,
) => <String, dynamic>{
  'code': instance.code,
  'shipment_id': instance.shipmentId,
  'detail': instance.detail,
};
