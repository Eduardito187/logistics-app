// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_account.dart';

part 'post_channels_accounts_response.g.dart';

@JsonSerializable()
class PostChannelsAccountsResponse {
  const PostChannelsAccountsResponse({required this.data});

  factory PostChannelsAccountsResponse.fromJson(Map<String, Object?> json) =>
      _$PostChannelsAccountsResponseFromJson(json);

  final CommerceAccount data;

  Map<String, Object?> toJson() => _$PostChannelsAccountsResponseToJson(this);
}
