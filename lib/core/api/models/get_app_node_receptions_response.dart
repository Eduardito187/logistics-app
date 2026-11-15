// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node_reception_summary.dart';
import 'list_meta.dart';

part 'get_app_node_receptions_response.g.dart';

@JsonSerializable()
class GetAppNodeReceptionsResponse {
  const GetAppNodeReceptionsResponse({required this.data, this.meta});

  factory GetAppNodeReceptionsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppNodeReceptionsResponseFromJson(json);

  final List<NodeReceptionSummary> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() => _$GetAppNodeReceptionsResponseToJson(this);
}
