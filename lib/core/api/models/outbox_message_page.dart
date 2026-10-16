// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meta15.dart';
import 'outbox_message.dart';

part 'outbox_message_page.g.dart';

@JsonSerializable()
class OutboxMessagePage {
  const OutboxMessagePage({required this.data, required this.meta});

  factory OutboxMessagePage.fromJson(Map<String, Object?> json) =>
      _$OutboxMessagePageFromJson(json);

  final List<OutboxMessage> data;
  final Meta15 meta;

  Map<String, Object?> toJson() => _$OutboxMessagePageToJson(this);
}
