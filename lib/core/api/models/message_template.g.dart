// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageTemplate _$MessageTemplateFromJson(Map<String, dynamic> json) =>
    MessageTemplate(
      id: json['id'] as String,
      messageType: MessageType.fromJson(json['message_type'] as String),
      channel: Channel.fromJson(json['channel'] as String),
      locale: json['locale'] as String,
      body: json['body'] as String,
      subject: json['subject'] as String?,
    );

Map<String, dynamic> _$MessageTemplateToJson(MessageTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message_type': instance.messageType,
      'channel': instance.channel,
      'locale': instance.locale,
      'subject': instance.subject,
      'body': instance.body,
    };
