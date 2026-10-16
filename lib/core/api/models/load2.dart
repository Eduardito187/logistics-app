// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'items2.dart';

part 'load2.g.dart';

@JsonSerializable()
class Load2 {
  const Load2({this.description, this.weightKg, this.items});

  factory Load2.fromJson(Map<String, Object?> json) => _$Load2FromJson(json);

  final String? description;
  @JsonKey(name: 'weight_kg')
  final double? weightKg;
  final List<Items2>? items;

  Map<String, Object?> toJson() => _$Load2ToJson(this);
}
