// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'send_staff_broadcast_data.g.dart';

@JsonSerializable()
class SendStaffBroadcastData {
  const SendStaffBroadcastData({this.id, this.recipientCount});

  factory SendStaffBroadcastData.fromJson(Map<String, Object?> json) =>
      _$SendStaffBroadcastDataFromJson(json);

  final String? id;
  @JsonKey(name: 'recipient_count')
  final int? recipientCount;

  Map<String, Object?> toJson() => _$SendStaffBroadcastDataToJson(this);
}
