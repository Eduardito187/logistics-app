// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_shipments_reschedule_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppShipmentsRescheduleResponse _$PostAppShipmentsRescheduleResponseFromJson(
  Map<String, dynamic> json,
) => PostAppShipmentsRescheduleResponse(
  data: RescheduleShipmentsResult.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PostAppShipmentsRescheduleResponseToJson(
  PostAppShipmentsRescheduleResponse instance,
) => <String, dynamic>{'data': instance.data};
