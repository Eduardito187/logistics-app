// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'asn_line.g.dart';

@JsonSerializable()
class AsnLine {
  const AsnLine({required this.sku, required this.expectedQuantity});

  factory AsnLine.fromJson(Map<String, Object?> json) =>
      _$AsnLineFromJson(json);

  final String sku;
  @JsonKey(name: 'expected_quantity')
  final int expectedQuantity;

  Map<String, Object?> toJson() => _$AsnLineToJson(this);
}
