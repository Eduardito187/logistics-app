// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'inbox_updated_event.g.dart';

/// Carga del evento `inbox.updated` en el canal `private-user.{id}`.
@JsonSerializable()
class InboxUpdatedEvent {
  const InboxUpdatedEvent({required this.unread});

  factory InboxUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$InboxUpdatedEventFromJson(json);

  final int unread;

  Map<String, Object?> toJson() => _$InboxUpdatedEventToJson(this);
}
