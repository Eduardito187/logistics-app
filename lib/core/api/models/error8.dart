// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error8.g.dart';

@JsonSerializable()
class Error8 {
  const Error8({required this.type, required this.message});

  factory Error8.fromJson(Map<String, Object?> json) => _$Error8FromJson(json);

  final String type;
  final String message;

  Map<String, Object?> toJson() => _$Error8ToJson(this);
}
