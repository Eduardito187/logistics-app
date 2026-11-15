// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_channels_search_facets_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetChannelsSearchFacetsResponse _$GetChannelsSearchFacetsResponseFromJson(
  Map<String, dynamic> json,
) => GetChannelsSearchFacetsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => CommerceSearchFacet.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetChannelsSearchFacetsResponseToJson(
  GetChannelsSearchFacetsResponse instance,
) => <String, dynamic>{'data': instance.data};
