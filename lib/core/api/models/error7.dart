// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error7.g.dart';

@JsonSerializable()
class Error7 {
  const Error7({required this.code, required this.message});

  factory Error7.fromJson(Map<String, Object?> json) => _$Error7FromJson(json);

  final String code;
  final String message;

  Map<String, Object?> toJson() => _$Error7ToJson(this);
}
