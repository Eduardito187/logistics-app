// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_plan_proposal_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratePlanProposalRequest _$GeneratePlanProposalRequestFromJson(
  Map<String, dynamic> json,
) => GeneratePlanProposalRequest(
  planDate: DateTime.parse(json['plan_date'] as String),
  vehicleId: json['vehicle_id'] as String,
  departAt: DateTime.parse(json['depart_at'] as String),
  stops: (json['stops'] as List<dynamic>)
      .map((e) => Stops2.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GeneratePlanProposalRequestToJson(
  GeneratePlanProposalRequest instance,
) => <String, dynamic>{
  'plan_date': instance.planDate.toIso8601String(),
  'vehicle_id': instance.vehicleId,
  'depart_at': instance.departAt.toIso8601String(),
  'stops': instance.stops,
};
