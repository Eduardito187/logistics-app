// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'token_verification.g.dart';

@JsonSerializable()
class TokenVerification {
  const TokenVerification({
    required this.tokenId,
    required this.permissionKeys,
  });

  factory TokenVerification.fromJson(Map<String, Object?> json) =>
      _$TokenVerificationFromJson(json);

  @JsonKey(name: 'token_id')
  final String tokenId;
  @JsonKey(name: 'permission_keys')
  final List<String> permissionKeys;

  Map<String, Object?> toJson() => _$TokenVerificationToJson(this);
}
