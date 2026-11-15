// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_search_result.dart';

part 'get_channels_search_products_response.g.dart';

@JsonSerializable()
class GetChannelsSearchProductsResponse {
  const GetChannelsSearchProductsResponse({required this.data});

  factory GetChannelsSearchProductsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsSearchProductsResponseFromJson(json);

  final CommerceSearchResult data;

  Map<String, Object?> toJson() =>
      _$GetChannelsSearchProductsResponseToJson(this);
}
