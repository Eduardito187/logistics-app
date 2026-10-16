// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status4.dart';

part 'data9.g.dart';

@JsonSerializable()
class Data9 {
  const Data9({required this.status});

  factory Data9.fromJson(Map<String, Object?> json) => _$Data9FromJson(json);

  final Status4 status;

  Map<String, Object?> toJson() => _$Data9ToJson(this);
}
