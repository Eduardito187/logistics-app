// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_integrations_promotions_id_expire_response.g.dart';

@JsonSerializable()
class PostIntegrationsPromotionsIdExpireResponse {
  const PostIntegrationsPromotionsIdExpireResponse({required this.data});

  factory PostIntegrationsPromotionsIdExpireResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsPromotionsIdExpireResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsPromotionsIdExpireResponseToJson(this);
}
