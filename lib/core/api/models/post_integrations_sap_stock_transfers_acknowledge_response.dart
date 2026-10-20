// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data20.dart';
import 'meta7.dart';

part 'post_integrations_sap_stock_transfers_acknowledge_response.g.dart';

@JsonSerializable()
class PostIntegrationsSapStockTransfersAcknowledgeResponse {
  const PostIntegrationsSapStockTransfersAcknowledgeResponse({
    required this.data,
    required this.meta,
  });

  factory PostIntegrationsSapStockTransfersAcknowledgeResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsSapStockTransfersAcknowledgeResponseFromJson(json);

  final Data20 data;
  final Meta7 meta;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsSapStockTransfersAcknowledgeResponseToJson(this);
}
