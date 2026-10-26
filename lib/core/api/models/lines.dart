// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'lines.g.dart';

@JsonSerializable()
class Lines {
  const Lines({required this.sku, required this.expectedQuantity});

  factory Lines.fromJson(Map<String, Object?> json) => _$LinesFromJson(json);

  final String sku;
  @JsonKey(name: 'expected_quantity')
  final int expectedQuantity;

  Map<String, Object?> toJson() => _$LinesToJson(this);
}
