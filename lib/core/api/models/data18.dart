// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data18.g.dart';

@JsonSerializable()
class Data18 {
  const Data18({this.status, this.plate});

  factory Data18.fromJson(Map<String, Object?> json) => _$Data18FromJson(json);

  final String? status;
  final String? plate;

  Map<String, Object?> toJson() => _$Data18ToJson(this);
}
