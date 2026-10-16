// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_odometer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordOdometerRequest _$RecordOdometerRequestFromJson(
  Map<String, dynamic> json,
) => RecordOdometerRequest(
  vehicleId: json['vehicle_id'] as String,
  km: (json['km'] as num).toInt(),
  source: RecordOdometerRequestSource.fromJson(json['source'] as String),
  readAt: DateTime.parse(json['read_at'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$RecordOdometerRequestToJson(
  RecordOdometerRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'km': instance.km,
  'source': instance.source,
  'read_at': instance.readAt.toIso8601String(),
  'note': instance.note,
};
