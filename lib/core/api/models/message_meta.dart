// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'message_meta.g.dart';

@JsonSerializable()
class MessageMeta {
  const MessageMeta({this.message});

  factory MessageMeta.fromJson(Map<String, Object?> json) =>
      _$MessageMetaFromJson(json);

  final String? message;

  Map<String, Object?> toJson() => _$MessageMetaToJson(this);
}
