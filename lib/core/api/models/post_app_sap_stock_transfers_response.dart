// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data8.dart';
import 'meta3.dart';

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

  final Data8 data;
  final Meta3 meta;

  Map<String, Object?> toJson() =>
      _$PostAppSapStockTransfersResponseToJson(this);
}
