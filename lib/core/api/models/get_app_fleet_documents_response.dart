// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_document.dart';
import 'collection_meta.dart';

part 'get_app_fleet_documents_response.g.dart';

@JsonSerializable()
class GetAppFleetDocumentsResponse {
  const GetAppFleetDocumentsResponse({this.data, this.meta});

  factory GetAppFleetDocumentsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetDocumentsResponseFromJson(json);

  final List<FleetDocument>? data;
  final CollectionMeta? meta;

  Map<String, Object?> toJson() => _$GetAppFleetDocumentsResponseToJson(this);
}
