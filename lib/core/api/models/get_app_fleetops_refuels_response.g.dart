// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_refuels_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsRefuelsResponse _$GetAppFleetopsRefuelsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetopsRefuelsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Refuel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppFleetopsRefuelsResponseToJson(
  GetAppFleetopsRefuelsResponse instance,
) => <String, dynamic>{'data': instance.data};
