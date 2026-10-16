// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'promise.dart';

part 'get_channels_promises_promise_id_response.g.dart';

@JsonSerializable()
class GetChannelsPromisesPromiseIdResponse {
  const GetChannelsPromisesPromiseIdResponse({this.data});

  factory GetChannelsPromisesPromiseIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsPromisesPromiseIdResponseFromJson(json);

  final Promise? data;

  Map<String, Object?> toJson() =>
      _$GetChannelsPromisesPromiseIdResponseToJson(this);
}
