// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'outbox_problem.g.dart';

/// RFC 7807 problem document.
@JsonSerializable()
class OutboxProblem {
  const OutboxProblem({
    required this.title,
    required this.status,
    this.type,
    this.detail,
  });

  factory OutboxProblem.fromJson(Map<String, Object?> json) =>
      _$OutboxProblemFromJson(json);

  final String? type;
  final String title;
  final int status;
  final String? detail;

  Map<String, Object?> toJson() => _$OutboxProblemToJson(this);
}
