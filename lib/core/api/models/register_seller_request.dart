// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_seller_request.g.dart';

@JsonSerializable()
class RegisterSellerRequest {
  const RegisterSellerRequest({
    required this.legalName,
    required this.taxId,
    required this.contactName,
    required this.email,
    this.phone,
  });

  factory RegisterSellerRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterSellerRequestFromJson(json);

  @JsonKey(name: 'legal_name')
  final String legalName;
  @JsonKey(name: 'tax_id')
  final String taxId;
  @JsonKey(name: 'contact_name')
  final String contactName;
  final String email;
  final String? phone;

  Map<String, Object?> toJson() => _$RegisterSellerRequestToJson(this);
}
