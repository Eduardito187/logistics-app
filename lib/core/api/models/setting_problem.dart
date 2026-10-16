// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'setting_problem.g.dart';

@JsonSerializable()
class SettingProblem {
  const SettingProblem({
    required this.title,
    required this.status,
    this.type,
    this.detail,
  });

  factory SettingProblem.fromJson(Map<String, Object?> json) =>
      _$SettingProblemFromJson(json);

  final String? type;
  final String title;
  final int status;
  final String? detail;

  Map<String, Object?> toJson() => _$SettingProblemToJson(this);
}
