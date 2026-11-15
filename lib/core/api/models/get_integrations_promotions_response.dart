// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_promotion_view.dart';
import 'list_meta.dart';

part 'get_integrations_promotions_response.g.dart';

@JsonSerializable()
class GetIntegrationsPromotionsResponse {
  const GetIntegrationsPromotionsResponse({required this.data, this.meta});

  factory GetIntegrationsPromotionsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetIntegrationsPromotionsResponseFromJson(json);

  final List<CommercePromotionView> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsPromotionsResponseToJson(this);
}
