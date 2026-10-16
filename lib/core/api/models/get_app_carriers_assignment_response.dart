// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'assignment.dart';

part 'get_app_carriers_assignment_response.g.dart';

@JsonSerializable()
class GetAppCarriersAssignmentResponse {
  const GetAppCarriersAssignmentResponse({required this.data});

  factory GetAppCarriersAssignmentResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppCarriersAssignmentResponseFromJson(json);

  final Assignment data;

  Map<String, Object?> toJson() =>
      _$GetAppCarriersAssignmentResponseToJson(this);
}
