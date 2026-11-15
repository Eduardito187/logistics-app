// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_open_cart_request.g.dart';

@JsonSerializable()
class CommerceOpenCartRequest {
  const CommerceOpenCartRequest({
    required this.sessionId,
    this.customerId,
    this.currency,
  });

  factory CommerceOpenCartRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceOpenCartRequestFromJson(json);

  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'customer_id')
  final String? customerId;

  /// ISO 4217 code; defaults to BOB when omitted.
  final String? currency;

  Map<String, Object?> toJson() => _$CommerceOpenCartRequestToJson(this);
}
