// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'money.g.dart';

@JsonSerializable()
class Money {
  const Money({required this.cents, required this.currency});

  factory Money.fromJson(Map<String, Object?> json) => _$MoneyFromJson(json);

  final int cents;
  final String currency;

  Map<String, Object?> toJson() => _$MoneyToJson(this);
}
