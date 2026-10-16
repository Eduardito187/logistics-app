// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reserve_promise_request.g.dart';

@JsonSerializable()
class ReservePromiseRequest {
  const ReservePromiseRequest({required this.ttlMinutes});

  factory ReservePromiseRequest.fromJson(Map<String, Object?> json) =>
      _$ReservePromiseRequestFromJson(json);

  @JsonKey(name: 'ttl_minutes')
  final int ttlMinutes;

  Map<String, Object?> toJson() => _$ReservePromiseRequestToJson(this);
}
