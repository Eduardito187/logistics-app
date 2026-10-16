// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_my_crew_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetMyCrewResponse _$GetAppFleetMyCrewResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetMyCrewResponse(
  data: json['data'] == null
      ? null
      : MyCrew.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppFleetMyCrewResponseToJson(
  GetAppFleetMyCrewResponse instance,
) => <String, dynamic>{'data': instance.data};
