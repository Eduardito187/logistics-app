// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data17.g.dart';

@JsonSerializable()
class Data17 {
  const Data17({this.status, this.plate});

  factory Data17.fromJson(Map<String, Object?> json) => _$Data17FromJson(json);

  final String? status;
  final String? plate;

  Map<String, Object?> toJson() => _$Data17ToJson(this);
}
