// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'promise.dart';

part 'post_channels_promises_promise_id_confirmation_response.g.dart';

@JsonSerializable()
class PostChannelsPromisesPromiseIdConfirmationResponse {
  const PostChannelsPromisesPromiseIdConfirmationResponse({this.data});

  factory PostChannelsPromisesPromiseIdConfirmationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostChannelsPromisesPromiseIdConfirmationResponseFromJson(json);

  final Promise? data;

  Map<String, Object?> toJson() =>
      _$PostChannelsPromisesPromiseIdConfirmationResponseToJson(this);
}
