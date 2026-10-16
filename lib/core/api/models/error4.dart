// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error4.g.dart';

@JsonSerializable()
class Error4 {
  const Error4({required this.code, required this.message, this.details});

  factory Error4.fromJson(Map<String, Object?> json) => _$Error4FromJson(json);

  final String code;
  final String message;
  final dynamic details;

  Map<String, Object?> toJson() => _$Error4ToJson(this);
}
