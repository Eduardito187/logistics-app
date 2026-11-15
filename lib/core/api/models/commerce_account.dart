// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_account_type.dart';
import 'commerce_address.dart';

part 'commerce_account.g.dart';

@JsonSerializable()
class CommerceAccount {
  const CommerceAccount({
    required this.id,
    required this.type,
    required this.userId,
    required this.displayName,
    required this.status,
    required this.addresses,
    this.taxId,
  });

  factory CommerceAccount.fromJson(Map<String, Object?> json) =>
      _$CommerceAccountFromJson(json);

  final String id;
  final CommerceAccountType type;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'tax_id')
  final String? taxId;
  final String status;
  final List<CommerceAddress> addresses;

  Map<String, Object?> toJson() => _$CommerceAccountToJson(this);
}
