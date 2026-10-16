// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'items.dart';

part 'load.g.dart';

@JsonSerializable()
class Load {
  const Load({this.description, this.weightKg, this.items});

  factory Load.fromJson(Map<String, Object?> json) => _$LoadFromJson(json);

  final String? description;
  @JsonKey(name: 'weight_kg')
  final double? weightKg;
  final List<Items>? items;

  Map<String, Object?> toJson() => _$LoadToJson(this);
}
