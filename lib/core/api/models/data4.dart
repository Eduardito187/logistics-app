// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data4.g.dart';

@JsonSerializable()
class Data4 {
  const Data4({this.status, this.helperId, this.active});

  factory Data4.fromJson(Map<String, Object?> json) => _$Data4FromJson(json);

  final String? status;
  @JsonKey(name: 'helper_id')
  final String? helperId;
  final bool? active;

  Map<String, Object?> toJson() => _$Data4ToJson(this);
}
