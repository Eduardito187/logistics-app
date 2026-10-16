// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'relay_outbox_request.g.dart';

@JsonSerializable()
class RelayOutboxRequest {
  const RelayOutboxRequest({this.limit});

  factory RelayOutboxRequest.fromJson(Map<String, Object?> json) =>
      _$RelayOutboxRequestFromJson(json);

  /// Max messages to dispatch in this run (defaults to server config).
  final int? limit;

  Map<String, Object?> toJson() => _$RelayOutboxRequestToJson(this);
}
