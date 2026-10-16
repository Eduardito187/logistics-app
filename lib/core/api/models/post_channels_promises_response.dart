// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'quoted_promise.dart';

part 'post_channels_promises_response.g.dart';

@JsonSerializable()
class PostChannelsPromisesResponse {
  const PostChannelsPromisesResponse({this.data});

  factory PostChannelsPromisesResponse.fromJson(Map<String, Object?> json) =>
      _$PostChannelsPromisesResponseFromJson(json);

  final QuotedPromise? data;

  Map<String, Object?> toJson() => _$PostChannelsPromisesResponseToJson(this);
}
