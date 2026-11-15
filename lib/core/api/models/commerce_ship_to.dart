// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_ship_to.g.dart';

@JsonSerializable()
class CommerceShipTo {
  const CommerceShipTo({
    required this.customerName,
    required this.addressText,
    this.reference,
    this.phone,
    this.email,
  });

  factory CommerceShipTo.fromJson(Map<String, Object?> json) =>
      _$CommerceShipToFromJson(json);

  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'address_text')
  final String addressText;
  final String? reference;
  final String? phone;
  final String? email;

  Map<String, Object?> toJson() => _$CommerceShipToToJson(this);
}
