// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_register_account_request_type.dart';

part 'commerce_register_account_request.g.dart';

@JsonSerializable()
class CommerceRegisterAccountRequest {
  const CommerceRegisterAccountRequest({
    required this.type,
    required this.userId,
    required this.displayName,
    this.taxId,
  });

  factory CommerceRegisterAccountRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceRegisterAccountRequestFromJson(json);

  final CommerceRegisterAccountRequestType type;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'tax_id')
  final String? taxId;

  Map<String, Object?> toJson() => _$CommerceRegisterAccountRequestToJson(this);
}
