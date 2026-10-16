// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error6.g.dart';

@JsonSerializable()
class Error6 {
  const Error6({required this.code, required this.message});

  factory Error6.fromJson(Map<String, Object?> json) => _$Error6FromJson(json);

  final String code;
  final String message;

  Map<String, Object?> toJson() => _$Error6ToJson(this);
}
