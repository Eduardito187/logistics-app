// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'return_line.g.dart';

@JsonSerializable()
class ReturnLine {
  const ReturnLine({
    required this.sku,
    required this.quantity,
    required this.reason,
  });

  factory ReturnLine.fromJson(Map<String, Object?> json) =>
      _$ReturnLineFromJson(json);

  final String sku;
  final int quantity;
  final String reason;

  Map<String, Object?> toJson() => _$ReturnLineToJson(this);
}
