// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'unit.g.dart';

@JsonSerializable()
class Unit {
  const Unit({required this.index, required this.total});

  factory Unit.fromJson(Map<String, Object?> json) => _$UnitFromJson(json);

  final int index;
  final int total;

  Map<String, Object?> toJson() => _$UnitToJson(this);
}
