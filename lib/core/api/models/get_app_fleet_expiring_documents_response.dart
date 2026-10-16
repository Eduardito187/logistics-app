// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expiring_document.dart';
import 'collection_meta.dart';

part 'get_app_fleet_expiring_documents_response.g.dart';

@JsonSerializable()
class GetAppFleetExpiringDocumentsResponse {
  const GetAppFleetExpiringDocumentsResponse({this.data, this.meta});

  factory GetAppFleetExpiringDocumentsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetExpiringDocumentsResponseFromJson(json);

  final List<ExpiringDocument>? data;
  final CollectionMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetAppFleetExpiringDocumentsResponseToJson(this);
}
