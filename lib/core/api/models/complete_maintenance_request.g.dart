// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_maintenance_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompleteMaintenanceRequest _$CompleteMaintenanceRequestFromJson(
  Map<String, dynamic> json,
) => CompleteMaintenanceRequest(
  items: (json['items'] as List<dynamic>)
      .map((e) => MaintenanceItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$CompleteMaintenanceRequestToJson(
  CompleteMaintenanceRequest instance,
) => <String, dynamic>{'items': instance.items, 'currency': instance.currency};
