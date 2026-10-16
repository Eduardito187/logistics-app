// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'set_setting_request.g.dart';

@JsonSerializable()
class SetSettingRequest {
  const SetSettingRequest({
    required this.key,
    required this.value,
    this.effectiveFrom,
    this.createdBy,
  });

  factory SetSettingRequest.fromJson(Map<String, Object?> json) =>
      _$SetSettingRequestFromJson(json);

  final String key;
  final dynamic value;
  @JsonKey(name: 'effective_from')
  final DateTime? effectiveFrom;
  @JsonKey(name: 'created_by')
  final String? createdBy;

  Map<String, Object?> toJson() => _$SetSettingRequestToJson(this);
}
