// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status3.dart';

part 'data8.g.dart';

@JsonSerializable()
class Data8 {
  const Data8({required this.status});

  factory Data8.fromJson(Map<String, Object?> json) => _$Data8FromJson(json);

  final Status3 status;

  Map<String, Object?> toJson() => _$Data8ToJson(this);
}
