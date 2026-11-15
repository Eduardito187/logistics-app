// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sent_by.dart';

part 'staff_broadcast.g.dart';

@JsonSerializable()
class StaffBroadcast {
  const StaffBroadcast({
    this.id,
    this.title,
    this.body,
    this.link,
    this.sentAt,
    this.audience,
    this.recipientCount,
    this.readCount,
    this.sentBy,
  });

  factory StaffBroadcast.fromJson(Map<String, Object?> json) =>
      _$StaffBroadcastFromJson(json);

  final String? id;
  final String? title;
  final String? body;
  final String? link;
  @JsonKey(name: 'sent_at')
  final DateTime? sentAt;
  final dynamic audience;
  @JsonKey(name: 'recipient_count')
  final int? recipientCount;
  @JsonKey(name: 'read_count')
  final int? readCount;
  @JsonKey(name: 'sent_by')
  final SentBy? sentBy;

  Map<String, Object?> toJson() => _$StaffBroadcastToJson(this);
}
