// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meta17.dart';
import 'stock_transfer.dart';

part 'stock_transfer_collection.g.dart';

@JsonSerializable()
class StockTransferCollection {
  const StockTransferCollection({required this.data, required this.meta});

  factory StockTransferCollection.fromJson(Map<String, Object?> json) =>
      _$StockTransferCollectionFromJson(json);

  final List<StockTransfer> data;
  final Meta17 meta;

  Map<String, Object?> toJson() => _$StockTransferCollectionToJson(this);
}
