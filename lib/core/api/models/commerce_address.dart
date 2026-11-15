// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_address.g.dart';

@JsonSerializable()
class CommerceAddress {
  const CommerceAddress({
    required this.label,
    required this.recipient,
    required this.line1,
    required this.city,
    required this.isDefault,
    this.line2,
    this.state,
    this.phone,
  });

  factory CommerceAddress.fromJson(Map<String, Object?> json) =>
      _$CommerceAddressFromJson(json);

  final String label;
  final String recipient;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String? phone;
  @JsonKey(name: 'is_default')
  final bool isDefault;

  Map<String, Object?> toJson() => _$CommerceAddressToJson(this);
}
