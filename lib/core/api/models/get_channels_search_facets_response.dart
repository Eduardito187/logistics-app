// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_search_facet.dart';

part 'get_channels_search_facets_response.g.dart';

@JsonSerializable()
class GetChannelsSearchFacetsResponse {
  const GetChannelsSearchFacetsResponse({required this.data});

  factory GetChannelsSearchFacetsResponse.fromJson(Map<String, Object?> json) =>
      _$GetChannelsSearchFacetsResponseFromJson(json);

  final List<CommerceSearchFacet> data;

  Map<String, Object?> toJson() =>
      _$GetChannelsSearchFacetsResponseToJson(this);
}
