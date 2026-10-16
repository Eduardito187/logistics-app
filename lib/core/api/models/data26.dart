// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data26.g.dart';

@JsonSerializable()
class Data26 {
  const Data26({required this.accepted, required this.key});

  factory Data26.fromJson(Map<String, Object?> json) => _$Data26FromJson(json);

  final bool accepted;
  final String key;

  Map<String, Object?> toJson() => _$Data26ToJson(this);
}
