// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_add_address_request.g.dart';

@JsonSerializable()
class CommerceAddAddressRequest {
  const CommerceAddAddressRequest({
    required this.label,
    required this.recipient,
    required this.line1,
    required this.city,
    this.line2,
    this.state,
    this.phone,
    this.isDefault,
  });

  factory CommerceAddAddressRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceAddAddressRequestFromJson(json);

  final String label;
  final String recipient;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String? phone;
  @JsonKey(name: 'is_default')
  final bool? isDefault;

  Map<String, Object?> toJson() => _$CommerceAddAddressRequestToJson(this);
}
