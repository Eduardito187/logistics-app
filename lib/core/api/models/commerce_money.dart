// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_money.g.dart';

@JsonSerializable()
class CommerceMoney {
  const CommerceMoney({required this.cents, required this.currency});

  factory CommerceMoney.fromJson(Map<String, Object?> json) =>
      _$CommerceMoneyFromJson(json);

  final int cents;
  final String currency;

  Map<String, Object?> toJson() => _$CommerceMoneyToJson(this);
}
