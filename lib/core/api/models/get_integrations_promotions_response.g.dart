// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_integrations_promotions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetIntegrationsPromotionsResponse _$GetIntegrationsPromotionsResponseFromJson(
  Map<String, dynamic> json,
) => GetIntegrationsPromotionsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => CommercePromotionView.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetIntegrationsPromotionsResponseToJson(
  GetIntegrationsPromotionsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
