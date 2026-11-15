// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'failures.dart';

part 'outbox_failures_request.g.dart';

@JsonSerializable()
class OutboxFailuresRequest {
  const OutboxFailuresRequest({required this.failures});

  factory OutboxFailuresRequest.fromJson(Map<String, Object?> json) =>
      _$OutboxFailuresRequestFromJson(json);

  final List<Failures> failures;

  Map<String, Object?> toJson() => _$OutboxFailuresRequestToJson(this);
}
