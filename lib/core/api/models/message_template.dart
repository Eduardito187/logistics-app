// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'channel.dart';
import 'message_type.dart';

part 'message_template.g.dart';

/// Message template for a type, channel and locale (P1-NOT-08).
@JsonSerializable()
class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.messageType,
    required this.channel,
    required this.locale,
    required this.body,
    this.subject,
  });

  factory MessageTemplate.fromJson(Map<String, Object?> json) =>
      _$MessageTemplateFromJson(json);

  final String id;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final Channel channel;
  final String locale;

  /// Only used by the email channel.
  final String? subject;

  /// Body text with {{variable}} placeholders.
  final String body;

  Map<String, Object?> toJson() => _$MessageTemplateToJson(this);
}
