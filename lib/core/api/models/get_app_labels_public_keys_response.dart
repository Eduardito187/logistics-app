// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'public_key_bundle.dart';

part 'get_app_labels_public_keys_response.g.dart';

@JsonSerializable()
class GetAppLabelsPublicKeysResponse {
  const GetAppLabelsPublicKeysResponse({required this.data});

  factory GetAppLabelsPublicKeysResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppLabelsPublicKeysResponseFromJson(json);

  final PublicKeyBundle data;

  Map<String, Object?> toJson() => _$GetAppLabelsPublicKeysResponseToJson(this);
}
