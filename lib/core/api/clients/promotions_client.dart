// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/commerce_change_promotion_rules_request.dart';
import '../models/commerce_create_promotion_request.dart';
import '../models/commerce_evaluate_promotions_request.dart';
import '../models/get_integrations_promotions_id_response.dart';
import '../models/get_integrations_promotions_response.dart';
import '../models/post_channels_promotions_evaluate_response.dart';
import '../models/post_integrations_promotions_id_activate_response.dart';
import '../models/post_integrations_promotions_id_expire_response.dart';
import '../models/post_integrations_promotions_id_rules_response.dart';
import '../models/post_integrations_promotions_response.dart';
import '../models/status9.dart';

part 'promotions_client.g.dart';

@RestApi()
abstract class PromotionsClient {
  factory PromotionsClient(Dio dio, {String? baseUrl}) = _PromotionsClient;

  /// Evaluate applicable promotions for a cart context (no side effects)
  @POST('/channels/promotions/evaluate')
  Future<PostChannelsPromotionsEvaluateResponse> evaluatePromotions({
    @Body() required CommerceEvaluatePromotionsRequest body,
  });

  /// List promotions.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/integrations/promotions')
  Future<GetIntegrationsPromotionsResponse> listPromotions({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('status') Status9? status,
    @Query('cursor') String? cursor,
  });

  /// Create a promotion
  @POST('/integrations/promotions')
  Future<PostIntegrationsPromotionsResponse> createPromotion({
    @Body() required CommerceCreatePromotionRequest body,
  });

  /// Get a promotion by id
  @GET('/integrations/promotions/{id}')
  Future<GetIntegrationsPromotionsIdResponse> getPromotion({
    @Path('id') required String id,
  });

  /// Activate a promotion
  @POST('/integrations/promotions/{id}/activate')
  Future<PostIntegrationsPromotionsIdActivateResponse> activatePromotion({
    @Path('id') required String id,
  });

  /// Expire a promotion
  @POST('/integrations/promotions/{id}/expire')
  Future<PostIntegrationsPromotionsIdExpireResponse> expirePromotion({
    @Path('id') required String id,
  });

  /// Change the rules of a promotion
  @POST('/integrations/promotions/{id}/rules')
  Future<PostIntegrationsPromotionsIdRulesResponse> changePromotionRules({
    @Path('id') required String id,
    @Body() required CommerceChangePromotionRulesRequest body,
  });
}
