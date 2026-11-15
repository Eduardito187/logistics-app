// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_cart_line.dart';

part 'commerce_cart.g.dart';

@JsonSerializable()
class CommerceCart {
  const CommerceCart({
    required this.id,
    required this.sessionId,
    required this.status,
    required this.currency,
    required this.lines,
    required this.totalCents,
    this.customerId,
  });

  factory CommerceCart.fromJson(Map<String, Object?> json) =>
      _$CommerceCartFromJson(json);

  final String id;
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @JsonKey(name: 'session_id')
  final String sessionId;

  /// Cart status (e.g. open, converted).
  final String status;
  final String currency;
  final List<CommerceCartLine> lines;
  @JsonKey(name: 'total_cents')
  final int totalCents;

  Map<String, Object?> toJson() => _$CommerceCartToJson(this);
}
