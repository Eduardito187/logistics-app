// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispatch_pending_stock_transfers_data.dart';
import 'message_meta.dart';

part 'post_app_sap_stock_transfers_dispatch_response.g.dart';

@JsonSerializable()
class PostAppSapStockTransfersDispatchResponse {
  const PostAppSapStockTransfersDispatchResponse({
    required this.data,
    required this.meta,
  });

  factory PostAppSapStockTransfersDispatchResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppSapStockTransfersDispatchResponseFromJson(json);

  final DispatchPendingStockTransfersData data;
  final MessageMeta meta;

  Map<String, Object?> toJson() =>
      _$PostAppSapStockTransfersDispatchResponseToJson(this);
}
