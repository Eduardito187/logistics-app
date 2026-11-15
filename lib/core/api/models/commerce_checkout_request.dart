// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ship_to.dart';

part 'commerce_checkout_request.g.dart';

@JsonSerializable()
class CommerceCheckoutRequest {
  const CommerceCheckoutRequest({required this.cartId, required this.shipTo});

  factory CommerceCheckoutRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceCheckoutRequestFromJson(json);

  @JsonKey(name: 'cart_id')
  final String cartId;
  @JsonKey(name: 'ship_to')
  final CommerceShipTo shipTo;

  Map<String, Object?> toJson() => _$CommerceCheckoutRequestToJson(this);
}
