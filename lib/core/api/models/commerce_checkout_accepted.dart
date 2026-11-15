// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_checkout_accepted.g.dart';

@JsonSerializable()
class CommerceCheckoutAccepted {
  const CommerceCheckoutAccepted({
    required this.accepted,
    this.customerName,
    this.currency,
  });

  factory CommerceCheckoutAccepted.fromJson(Map<String, Object?> json) =>
      _$CommerceCheckoutAcceptedFromJson(json);

  final bool accepted;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  final String? currency;

  Map<String, Object?> toJson() => _$CommerceCheckoutAcceptedToJson(this);
}
