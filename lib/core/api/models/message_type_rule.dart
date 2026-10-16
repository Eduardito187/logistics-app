// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'channel.dart';
import 'escalate_condition.dart';
import 'message_type.dart';

part 'message_type_rule.g.dart';

/// Effective cascade rule for a message type (P1-NOT-01).
@JsonSerializable()
class MessageTypeRule {
  const MessageTypeRule({
    required this.messageType,
    required this.channels,
    required this.escalateWhen,
    required this.customized,
  });

  factory MessageTypeRule.fromJson(Map<String, Object?> json) =>
      _$MessageTypeRuleFromJson(json);

  @JsonKey(name: 'message_type')
  final MessageType messageType;

  /// Policy channels, in cascade order.
  final List<Channel> channels;
  @JsonKey(name: 'escalate_when')
  final EscalateCondition escalateWhen;

  /// True when the operator overrode the ADR 006 default for this type.
  final bool customized;

  Map<String, Object?> toJson() => _$MessageTypeRuleToJson(this);
}
