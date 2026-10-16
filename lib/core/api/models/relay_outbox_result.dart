// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'relay_outbox_result.g.dart';

@JsonSerializable()
class RelayOutboxResult {
  const RelayOutboxResult({
    required this.pulled,
    required this.dispatched,
    required this.failed,
    required this.deadLettered,
  });

  factory RelayOutboxResult.fromJson(Map<String, Object?> json) =>
      _$RelayOutboxResultFromJson(json);

  final int pulled;
  final int dispatched;
  final int failed;
  @JsonKey(name: 'dead_lettered')
  final int deadLettered;

  Map<String, Object?> toJson() => _$RelayOutboxResultToJson(this);
}
