// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_plans_plan_id_sequence_request_body.g.dart';

@JsonSerializable()
class AppPlansPlanIdSequenceRequestBody {
  const AppPlansPlanIdSequenceRequestBody({required this.orderedShipmentIds});

  factory AppPlansPlanIdSequenceRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppPlansPlanIdSequenceRequestBodyFromJson(json);

  @JsonKey(name: 'ordered_shipment_ids')
  final List<String> orderedShipmentIds;

  Map<String, Object?> toJson() =>
      _$AppPlansPlanIdSequenceRequestBodyToJson(this);
}
