// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_cancel_order_request.g.dart';

/// Optional reason for the cancellation (free text).
@JsonSerializable()
class CommerceCancelOrderRequest {
  const CommerceCancelOrderRequest({this.reason});

  factory CommerceCancelOrderRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceCancelOrderRequestFromJson(json);

  final String? reason;

  Map<String, Object?> toJson() => _$CommerceCancelOrderRequestToJson(this);
}
