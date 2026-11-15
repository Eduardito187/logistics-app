// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_user_preferences_request.g.dart';

@JsonSerializable()
class UpdateUserPreferencesRequest {
  const UpdateUserPreferencesRequest({
    required this.preferences,
    this.updatedAt,
  });

  factory UpdateUserPreferencesRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateUserPreferencesRequestFromJson(json);

  /// Merge; keys not sent are kept and null deletes a key. Known keys (ui.*, scan.*, printer.*, notifications.muted_kinds, map.follow_location) or the free app.* namespace (max 4 KB per value).
  final dynamic preferences;

  /// When the change happened on the device (last-write-wins per key).
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => _$UpdateUserPreferencesRequestToJson(this);
}
