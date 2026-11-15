// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_assignment.dart';
import 'list_meta.dart';

part 'get_app_carriers_me_assignments_response.g.dart';

@JsonSerializable()
class GetAppCarriersMeAssignmentsResponse {
  const GetAppCarriersMeAssignmentsResponse({
    required this.data,
    required this.meta,
  });

  factory GetAppCarriersMeAssignmentsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppCarriersMeAssignmentsResponseFromJson(json);

  final List<CarrierAssignment> data;
  final ListMeta meta;

  Map<String, Object?> toJson() =>
      _$GetAppCarriersMeAssignmentsResponseToJson(this);
}
