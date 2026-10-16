// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'channel.dart';
import 'escalate_condition.dart';
import 'message_type.dart';

part 'set_message_type_rule_request.g.dart';

@JsonSerializable()
class SetMessageTypeRuleRequest {
  const SetMessageTypeRuleRequest({
    required this.messageType,
    required this.channels,
    required this.escalateWhen,
  });

  factory SetMessageTypeRuleRequest.fromJson(Map<String, Object?> json) =>
      _$SetMessageTypeRuleRequestFromJson(json);

  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final List<Channel> channels;
  @JsonKey(name: 'escalate_when')
  final EscalateCondition escalateWhen;

  Map<String, Object?> toJson() => _$SetMessageTypeRuleRequestToJson(this);
}
