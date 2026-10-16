// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data14.dart';

part 'post_integrations_fleet_documents_response.g.dart';

@JsonSerializable()
class PostIntegrationsFleetDocumentsResponse {
  const PostIntegrationsFleetDocumentsResponse({this.data});

  factory PostIntegrationsFleetDocumentsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsFleetDocumentsResponseFromJson(json);

  final Data14? data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsFleetDocumentsResponseToJson(this);
}
