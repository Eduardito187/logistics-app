// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'discard_outbox_message_request.g.dart';

@JsonSerializable()
class DiscardOutboxMessageRequest {
  const DiscardOutboxMessageRequest({required this.reason});

  factory DiscardOutboxMessageRequest.fromJson(Map<String, Object?> json) =>
      _$DiscardOutboxMessageRequestFromJson(json);

  /// Audit reason stored in last_error.
  final String reason;

  Map<String, Object?> toJson() => _$DiscardOutboxMessageRequestToJson(this);
}
