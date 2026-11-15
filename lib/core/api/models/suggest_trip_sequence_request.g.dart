// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggest_trip_sequence_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestTripSequenceRequest _$SuggestTripSequenceRequestFromJson(
  Map<String, dynamic> json,
) => SuggestTripSequenceRequest(
  date: DateTime.parse(json['date'] as String),
  vehicleId: json['vehicle_id'] as String,
  shipmentIds: (json['shipment_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  departAt: json['depart_at'] == null
      ? null
      : DateTime.parse(json['depart_at'] as String),
);

Map<String, dynamic> _$SuggestTripSequenceRequestToJson(
  SuggestTripSequenceRequest instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'vehicle_id': instance.vehicleId,
  'depart_at': instance.departAt?.toIso8601String(),
  'shipment_ids': instance.shipmentIds,
};
