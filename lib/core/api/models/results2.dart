// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status12.dart';

part 'results2.g.dart';

@JsonSerializable()
class Results2 {
  const Results2({
    required this.index,
    required this.status,
    this.fixId,
    this.errors,
  });

  factory Results2.fromJson(Map<String, Object?> json) =>
      _$Results2FromJson(json);

  final int index;
  @JsonKey(name: 'fix_id')
  final String? fixId;
  final Status12 status;
  final Map<String, List<String>>? errors;

  Map<String, Object?> toJson() => _$Results2ToJson(this);
}
