// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_notifications_read_all_request_body.g.dart';

@JsonSerializable()
class AppNotificationsReadAllRequestBody {
  const AppNotificationsReadAllRequestBody({this.upTo});

  factory AppNotificationsReadAllRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppNotificationsReadAllRequestBodyFromJson(json);

  /// Mark as read only notifications created up to this instant (inclusive). Defaults to now; future values are clamped. Monotonic.
  @JsonKey(name: 'up_to')
  final DateTime? upTo;

  Map<String, Object?> toJson() =>
      _$AppNotificationsReadAllRequestBodyToJson(this);
}
