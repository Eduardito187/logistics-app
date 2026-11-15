// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_account.dart';

part 'get_channels_accounts_account_response.g.dart';

@JsonSerializable()
class GetChannelsAccountsAccountResponse {
  const GetChannelsAccountsAccountResponse({required this.data});

  factory GetChannelsAccountsAccountResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsAccountsAccountResponseFromJson(json);

  final CommerceAccount data;

  Map<String, Object?> toJson() =>
      _$GetChannelsAccountsAccountResponseToJson(this);
}
