// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'set_setting_accepted_data.g.dart';

@JsonSerializable()
class SetSettingAcceptedData {
  const SetSettingAcceptedData({required this.accepted, required this.key});

  factory SetSettingAcceptedData.fromJson(Map<String, Object?> json) =>
      _$SetSettingAcceptedDataFromJson(json);

  final bool accepted;
  final String key;

  Map<String, Object?> toJson() => _$SetSettingAcceptedDataToJson(this);
}
