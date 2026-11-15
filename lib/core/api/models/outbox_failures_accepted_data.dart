// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'outbox_failures_accepted_data.g.dart';

@JsonSerializable()
class OutboxFailuresAcceptedData {
  const OutboxFailuresAcceptedData({
    required this.accepted,
    this.received,
    this.stored,
    this.duplicates,
  });

  factory OutboxFailuresAcceptedData.fromJson(Map<String, Object?> json) =>
      _$OutboxFailuresAcceptedDataFromJson(json);

  final bool accepted;
  final int? received;
  final int? stored;
  final int? duplicates;

  Map<String, Object?> toJson() => _$OutboxFailuresAcceptedDataToJson(this);
}
