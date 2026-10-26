// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_order.dart';

part 'return_order_collection.g.dart';

@JsonSerializable()
class ReturnOrderCollection {
  const ReturnOrderCollection({required this.data});

  factory ReturnOrderCollection.fromJson(Map<String, Object?> json) =>
      _$ReturnOrderCollectionFromJson(json);

  final List<ReturnOrder> data;

  Map<String, Object?> toJson() => _$ReturnOrderCollectionToJson(this);
}
