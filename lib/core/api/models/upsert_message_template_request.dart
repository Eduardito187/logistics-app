// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'channel.dart';
import 'message_type.dart';

part 'upsert_message_template_request.g.dart';

@JsonSerializable()
class UpsertMessageTemplateRequest {
  const UpsertMessageTemplateRequest({
    required this.messageType,
    required this.channel,
    required this.body,
    this.subject,
    this.locale = 'es',
  });

  factory UpsertMessageTemplateRequest.fromJson(Map<String, Object?> json) =>
      _$UpsertMessageTemplateRequestFromJson(json);

  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final Channel channel;
  final String? locale;
  final String? subject;
  final String body;

  Map<String, Object?> toJson() => _$UpsertMessageTemplateRequestToJson(this);
}
