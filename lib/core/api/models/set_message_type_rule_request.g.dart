// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_message_type_rule_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetMessageTypeRuleRequest _$SetMessageTypeRuleRequestFromJson(
  Map<String, dynamic> json,
) => SetMessageTypeRuleRequest(
  messageType: MessageType.fromJson(json['message_type'] as String),
  channels: (json['channels'] as List<dynamic>)
      .map((e) => Channel.fromJson(e as String))
      .toList(),
  escalateWhen: EscalateCondition.fromJson(json['escalate_when'] as String),
);

Map<String, dynamic> _$SetMessageTypeRuleRequestToJson(
  SetMessageTypeRuleRequest instance,
) => <String, dynamic>{
  'message_type': instance.messageType,
  'channels': instance.channels,
  'escalate_when': instance.escalateWhen,
};
