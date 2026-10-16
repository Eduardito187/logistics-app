// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plan.dart';
import 'meta.dart';

part 'get_app_plans_response.g.dart';

@JsonSerializable()
class GetAppPlansResponse {
  const GetAppPlansResponse({required this.data, required this.meta});

  factory GetAppPlansResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppPlansResponseFromJson(json);

  final List<Plan> data;
  final Meta meta;

  Map<String, Object?> toJson() => _$GetAppPlansResponseToJson(this);
}
