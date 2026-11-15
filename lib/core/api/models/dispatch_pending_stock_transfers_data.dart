// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispatch_pending_stock_transfers_data_status.dart';

part 'dispatch_pending_stock_transfers_data.g.dart';

@JsonSerializable()
class DispatchPendingStockTransfersData {
  const DispatchPendingStockTransfersData({required this.status});

  factory DispatchPendingStockTransfersData.fromJson(
    Map<String, Object?> json,
  ) => _$DispatchPendingStockTransfersDataFromJson(json);

  final DispatchPendingStockTransfersDataStatus status;

  Map<String, Object?> toJson() =>
      _$DispatchPendingStockTransfersDataToJson(this);
}
