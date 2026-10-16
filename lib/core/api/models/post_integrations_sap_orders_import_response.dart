// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'imported_sap_order.dart';
import 'meta6.dart';

part 'post_integrations_sap_orders_import_response.g.dart';

@JsonSerializable()
class PostIntegrationsSapOrdersImportResponse {
  const PostIntegrationsSapOrdersImportResponse({
    required this.data,
    required this.meta,
  });

  factory PostIntegrationsSapOrdersImportResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsSapOrdersImportResponseFromJson(json);

  final List<ImportedSapOrder> data;
  final Meta6 meta;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsSapOrdersImportResponseToJson(this);
}
