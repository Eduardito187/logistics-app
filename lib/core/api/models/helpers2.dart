// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'helpers2.g.dart';

@JsonSerializable()
class Helpers2 {
  const Helpers2({this.id, this.name});

  factory Helpers2.fromJson(Map<String, Object?> json) =>
      _$Helpers2FromJson(json);

  final String? id;
  final String? name;

  Map<String, Object?> toJson() => _$Helpers2ToJson(this);
}
