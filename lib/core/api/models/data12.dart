// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'public_unit.dart';

part 'data12.g.dart';

@JsonSerializable()
class Data12 {
  const Data12({required this.units});

  factory Data12.fromJson(Map<String, Object?> json) => _$Data12FromJson(json);

  final List<PublicUnit> units;

  Map<String, Object?> toJson() => _$Data12ToJson(this);
}
