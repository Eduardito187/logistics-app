// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_account.dart';

part 'post_channels_accounts_account_addresses_response.g.dart';

@JsonSerializable()
class PostChannelsAccountsAccountAddressesResponse {
  const PostChannelsAccountsAccountAddressesResponse({required this.data});

  factory PostChannelsAccountsAccountAddressesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostChannelsAccountsAccountAddressesResponseFromJson(json);

  final CommerceAccount data;

  Map<String, Object?> toJson() =>
      _$PostChannelsAccountsAccountAddressesResponseToJson(this);
}
