// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'helpers3.g.dart';

@JsonSerializable()
class Helpers3 {
  const Helpers3({required this.id, required this.name});

  factory Helpers3.fromJson(Map<String, Object?> json) =>
      _$Helpers3FromJson(json);

  final String id;
  final String? name;

  Map<String, Object?> toJson() => _$Helpers3ToJson(this);
}
