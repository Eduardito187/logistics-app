// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'define_maintenance_plan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefineMaintenancePlanRequest _$DefineMaintenancePlanRequestFromJson(
  Map<String, dynamic> json,
) => DefineMaintenancePlanRequest(
  vehicleId: json['vehicle_id'] as String,
  serviceKind: DefineMaintenancePlanRequestServiceKind.fromJson(
    json['service_kind'] as String,
  ),
  intervalKm: (json['interval_km'] as num?)?.toInt(),
  intervalDays: (json['interval_days'] as num?)?.toInt(),
);

Map<String, dynamic> _$DefineMaintenancePlanRequestToJson(
  DefineMaintenancePlanRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'service_kind': instance.serviceKind,
  'interval_km': instance.intervalKm,
  'interval_days': instance.intervalDays,
};
