// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_carriers_settlements_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppCarriersSettlementsResponse _$GetAppCarriersSettlementsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppCarriersSettlementsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppCarriersSettlementsResponseToJson(
  GetAppCarriersSettlementsResponse instance,
) => <String, dynamic>{'data': instance.data};
