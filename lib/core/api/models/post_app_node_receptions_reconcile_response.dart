// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node_reception_view.dart';

part 'post_app_node_receptions_reconcile_response.g.dart';

@JsonSerializable()
class PostAppNodeReceptionsReconcileResponse {
  const PostAppNodeReceptionsReconcileResponse({required this.data});

  factory PostAppNodeReceptionsReconcileResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppNodeReceptionsReconcileResponseFromJson(json);

  final NodeReceptionView data;

  Map<String, Object?> toJson() =>
      _$PostAppNodeReceptionsReconcileResponseToJson(this);
}
