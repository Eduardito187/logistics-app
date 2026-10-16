// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stops2.dart';

part 'generate_plan_proposal_request.g.dart';

@JsonSerializable()
class GeneratePlanProposalRequest {
  const GeneratePlanProposalRequest({
    required this.planDate,
    required this.vehicleId,
    required this.departAt,
    required this.stops,
  });

  factory GeneratePlanProposalRequest.fromJson(Map<String, Object?> json) =>
      _$GeneratePlanProposalRequestFromJson(json);

  @JsonKey(name: 'plan_date')
  final DateTime planDate;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;

  /// Depot departure time, ISO-8601
  @JsonKey(name: 'depart_at')
  final DateTime departAt;
  final List<Stops2> stops;

  Map<String, Object?> toJson() => _$GeneratePlanProposalRequestToJson(this);
}
