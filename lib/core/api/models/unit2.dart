// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'unit2.g.dart';

@JsonSerializable()
class Unit2 {
  const Unit2({this.index, this.total});

  factory Unit2.fromJson(Map<String, Object?> json) => _$Unit2FromJson(json);

  final int? index;
  final int? total;

  Map<String, Object?> toJson() => _$Unit2ToJson(this);
}
