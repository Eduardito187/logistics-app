// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_shipments_reschedule_preview_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppShipmentsReschedulePreviewResponse
_$PostAppShipmentsReschedulePreviewResponseFromJson(
  Map<String, dynamic> json,
) => PostAppShipmentsReschedulePreviewResponse(
  data: RescheduleShipmentsResult.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PostAppShipmentsReschedulePreviewResponseToJson(
  PostAppShipmentsReschedulePreviewResponse instance,
) => <String, dynamic>{'data': instance.data};
