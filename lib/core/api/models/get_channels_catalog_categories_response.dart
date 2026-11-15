// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_category.dart';

part 'get_channels_catalog_categories_response.g.dart';

@JsonSerializable()
class GetChannelsCatalogCategoriesResponse {
  const GetChannelsCatalogCategoriesResponse({required this.data});

  factory GetChannelsCatalogCategoriesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsCatalogCategoriesResponseFromJson(json);

  final List<CommerceCategory> data;

  Map<String, Object?> toJson() =>
      _$GetChannelsCatalogCategoriesResponseToJson(this);
}
