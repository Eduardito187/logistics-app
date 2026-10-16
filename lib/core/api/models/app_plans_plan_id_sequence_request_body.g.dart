// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_plans_plan_id_sequence_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppPlansPlanIdSequenceRequestBody _$AppPlansPlanIdSequenceRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppPlansPlanIdSequenceRequestBody(
  orderedShipmentIds: (json['ordered_shipment_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AppPlansPlanIdSequenceRequestBodyToJson(
  AppPlansPlanIdSequenceRequestBody instance,
) => <String, dynamic>{'ordered_shipment_ids': instance.orderedShipmentIds};
