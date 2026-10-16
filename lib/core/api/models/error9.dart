// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error9.g.dart';

@JsonSerializable()
class Error9 {
  const Error9({required this.message});

  factory Error9.fromJson(Map<String, Object?> json) => _$Error9FromJson(json);

  final String message;

  Map<String, Object?> toJson() => _$Error9ToJson(this);
}
