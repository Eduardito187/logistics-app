// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'acknowledge_stock_transfer_data.dart';
import 'message_meta.dart';

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

  final AcknowledgeStockTransferData data;
  final MessageMeta meta;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsSapStockTransfersAcknowledgeResponseToJson(this);
}
