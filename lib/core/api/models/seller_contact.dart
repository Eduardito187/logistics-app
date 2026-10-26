// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'seller_contact.g.dart';

@JsonSerializable()
class SellerContact {
  const SellerContact({
    required this.contactName,
    required this.email,
    this.phone,
  });

  factory SellerContact.fromJson(Map<String, Object?> json) =>
      _$SellerContactFromJson(json);

  @JsonKey(name: 'contact_name')
  final String contactName;
  final String email;
  final String? phone;

  Map<String, Object?> toJson() => _$SellerContactToJson(this);
}
