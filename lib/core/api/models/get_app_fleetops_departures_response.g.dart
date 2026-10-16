// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_departures_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsDeparturesResponse _$GetAppFleetopsDeparturesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetopsDeparturesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Departure.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppFleetopsDeparturesResponseToJson(
  GetAppFleetopsDeparturesResponse instance,
) => <String, dynamic>{'data': instance.data};
