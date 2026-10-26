// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fixed_fee.g.dart';

@JsonSerializable()
class FixedFee {
  const FixedFee({required this.cents, required this.currency});

  factory FixedFee.fromJson(Map<String, Object?> json) =>
      _$FixedFeeFromJson(json);

  final int cents;
  final String currency;

  Map<String, Object?> toJson() => _$FixedFeeToJson(this);
}
