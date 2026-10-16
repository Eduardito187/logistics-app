// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data26.dart';

part 'set_setting_accepted.g.dart';

@JsonSerializable()
class SetSettingAccepted {
  const SetSettingAccepted({required this.data});

  factory SetSettingAccepted.fromJson(Map<String, Object?> json) =>
      _$SetSettingAcceptedFromJson(json);

  final Data26 data;

  Map<String, Object?> toJson() => _$SetSettingAcceptedToJson(this);
}
