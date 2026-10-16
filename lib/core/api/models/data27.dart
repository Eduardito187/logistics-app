// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data27.g.dart';

@JsonSerializable()
class Data27 {
  const Data27({required this.accepted, required this.key});

  factory Data27.fromJson(Map<String, Object?> json) => _$Data27FromJson(json);

  final bool accepted;
  final String key;

  Map<String, Object?> toJson() => _$Data27ToJson(this);
}
