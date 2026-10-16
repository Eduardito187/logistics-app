// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_carriers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppCarriersResponse _$GetAppCarriersResponseFromJson(
  Map<String, dynamic> json,
) => GetAppCarriersResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Carrier.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : MetaSealed.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppCarriersResponseToJson(
  GetAppCarriersResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
