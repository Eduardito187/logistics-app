// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_promotion_view.dart';

part 'get_integrations_promotions_id_response.g.dart';

@JsonSerializable()
class GetIntegrationsPromotionsIdResponse {
  const GetIntegrationsPromotionsIdResponse({required this.data});

  factory GetIntegrationsPromotionsIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetIntegrationsPromotionsIdResponseFromJson(json);

  final CommercePromotionView data;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsPromotionsIdResponseToJson(this);
}
