// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error2.g.dart';

@JsonSerializable()
class Error2 {
  const Error2({required this.type, required this.message});

  factory Error2.fromJson(Map<String, Object?> json) => _$Error2FromJson(json);

  final String type;
  final String message;

  Map<String, Object?> toJson() => _$Error2ToJson(this);
}
