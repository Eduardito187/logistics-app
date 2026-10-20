// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_issue_type.dart';

part 'delivery_issue_request.g.dart';

@JsonSerializable()
class DeliveryIssueRequest {
  const DeliveryIssueRequest({
    required this.type,
    required this.occurredAt,
    this.note,
    this.lat,
    this.lng,
    this.photoPath,
    this.idempotencyKey,
  });

  factory DeliveryIssueRequest.fromJson(Map<String, Object?> json) =>
      _$DeliveryIssueRequestFromJson(json);

  final DeliveryIssueType type;
  final String? note;
  final double? lat;
  final double? lng;

  /// When the issue happened in the field (sealed by the app, even offline).
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  /// Optional evidence photo path (uploaded via the delivery photos endpoint).
  @JsonKey(name: 'photo_path')
  final String? photoPath;

  /// Fallback idempotency key when the Idempotency-Key header is not sent.
  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;

  Map<String, Object?> toJson() => _$DeliveryIssueRequestToJson(this);
}
