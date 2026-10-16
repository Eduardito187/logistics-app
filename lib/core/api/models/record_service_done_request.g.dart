// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_service_done_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordServiceDoneRequest _$RecordServiceDoneRequestFromJson(
  Map<String, dynamic> json,
) => RecordServiceDoneRequest(
  odometerKm: (json['odometer_km'] as num?)?.toInt(),
);

Map<String, dynamic> _$RecordServiceDoneRequestToJson(
  RecordServiceDoneRequest instance,
) => <String, dynamic>{'odometer_km': instance.odometerKm};
