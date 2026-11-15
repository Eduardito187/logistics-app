// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_account.dart';

part 'get_channels_accounts_by_user_user_id_response.g.dart';

@JsonSerializable()
class GetChannelsAccountsByUserUserIdResponse {
  const GetChannelsAccountsByUserUserIdResponse({required this.data});

  factory GetChannelsAccountsByUserUserIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsAccountsByUserUserIdResponseFromJson(json);

  final CommerceAccount data;

  Map<String, Object?> toJson() =>
      _$GetChannelsAccountsByUserUserIdResponseToJson(this);
}
