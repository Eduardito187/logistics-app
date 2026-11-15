// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_set_helper_availability_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetSetHelperAvailabilityData _$FleetSetHelperAvailabilityDataFromJson(
  Map<String, dynamic> json,
) => FleetSetHelperAvailabilityData(
  status: json['status'] as String?,
  helperId: json['helper_id'] as String?,
  active: json['active'] as bool?,
);

Map<String, dynamic> _$FleetSetHelperAvailabilityDataToJson(
  FleetSetHelperAvailabilityData instance,
) => <String, dynamic>{
  'status': instance.status,
  'helper_id': instance.helperId,
  'active': instance.active,
};
