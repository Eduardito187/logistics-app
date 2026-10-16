// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_plans_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppPlansResponse _$GetAppPlansResponseFromJson(Map<String, dynamic> json) =>
    GetAppPlansResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetAppPlansResponseToJson(
  GetAppPlansResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
