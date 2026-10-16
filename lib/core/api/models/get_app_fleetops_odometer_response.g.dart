// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_odometer_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsOdometerResponse _$GetAppFleetopsOdometerResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetopsOdometerResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => OdometerReading.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppFleetopsOdometerResponseToJson(
  GetAppFleetopsOdometerResponse instance,
) => <String, dynamic>{'data': instance.data};
