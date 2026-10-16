// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_type_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageTypeRule _$MessageTypeRuleFromJson(Map<String, dynamic> json) =>
    MessageTypeRule(
      messageType: MessageType.fromJson(json['message_type'] as String),
      channels: (json['channels'] as List<dynamic>)
          .map((e) => Channel.fromJson(e as String))
          .toList(),
      escalateWhen: EscalateCondition.fromJson(json['escalate_when'] as String),
      customized: json['customized'] as bool,
    );

Map<String, dynamic> _$MessageTypeRuleToJson(MessageTypeRule instance) =>
    <String, dynamic>{
      'message_type': instance.messageType,
      'channels': instance.channels,
      'escalate_when': instance.escalateWhen,
      'customized': instance.customized,
    };
