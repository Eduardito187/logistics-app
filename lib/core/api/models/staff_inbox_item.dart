// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_inbox_item_kind.dart';

part 'staff_inbox_item.g.dart';

@JsonSerializable()
class StaffInboxItem {
  const StaffInboxItem({
    this.kind,
    this.severity,
    this.id,
    this.title,
    this.body,
    this.link,
    this.sentAt,
    this.read,
    this.readAt,
  });

  factory StaffInboxItem.fromJson(Map<String, Object?> json) =>
      _$StaffInboxItemFromJson(json);

  /// notice = aviso interno (se marca leído); alert = alerta de flota sin reconocer; document = documento de flota por vencer o vencido. alert y document solo llegan a admin y supervisor.
  final StaffInboxItemKind? kind;

  /// Para alert: su severidad. Para document: expired | expiring. Null en notice.
  final String? severity;

  /// UUID en notice y alert; clave compuesta en document
  final String? id;
  final String? title;
  final String? body;
  final String? link;
  @JsonKey(name: 'sent_at')
  final DateTime? sentAt;
  final bool? read;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;

  Map<String, Object?> toJson() => _$StaffInboxItemToJson(this);
}
