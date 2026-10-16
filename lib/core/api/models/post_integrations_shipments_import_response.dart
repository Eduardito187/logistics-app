// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'import_report.dart';

part 'post_integrations_shipments_import_response.g.dart';

@JsonSerializable()
class PostIntegrationsShipmentsImportResponse {
  const PostIntegrationsShipmentsImportResponse({required this.data});

  factory PostIntegrationsShipmentsImportResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsShipmentsImportResponseFromJson(json);

  final ImportReport data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsShipmentsImportResponseToJson(this);
}
