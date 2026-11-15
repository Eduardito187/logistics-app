// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'enqueue_stock_transfer_data.dart';
import 'message_meta.dart';

part 'post_app_sap_stock_transfers_response.g.dart';

@JsonSerializable()
class PostAppSapStockTransfersResponse {
  const PostAppSapStockTransfersResponse({
    required this.data,
    required this.meta,
  });

  factory PostAppSapStockTransfersResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppSapStockTransfersResponseFromJson(json);

  final EnqueueStockTransferData data;
  final MessageMeta meta;

  Map<String, Object?> toJson() =>
      _$PostAppSapStockTransfersResponseToJson(this);
}
