// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error5.g.dart';

@JsonSerializable()
class Error5 {
  const Error5({required this.code, required this.message});

  factory Error5.fromJson(Map<String, Object?> json) => _$Error5FromJson(json);

  final String code;
  final String message;

  Map<String, Object?> toJson() => _$Error5ToJson(this);
}
