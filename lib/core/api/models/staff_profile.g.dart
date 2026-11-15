// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffProfile _$StaffProfileFromJson(Map<String, dynamic> json) => StaffProfile(
  city: json['city'] as String?,
  cityName: json['city_name'] as String?,
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  node: json['node'] == null
      ? null
      : StaffNode.fromJson(json['node'] as Map<String, dynamic>),
  driverId: json['driver_id'] as String?,
  carrierId: json['carrier_id'] as String?,
  phone: json['phone'] as String?,
  nationalId: json['national_id'] as String?,
  photoUrl: json['photo_url'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  personal: StaffPersonalData.fromJson(
    json['personal'] as Map<String, dynamic>,
  ),
  driver: json['driver'] == null
      ? null
      : StaffDriverData.fromJson(json['driver'] as Map<String, dynamic>),
  currentVehicle: json['current_vehicle'] == null
      ? null
      : CurrentVehicle.fromJson(
          json['current_vehicle'] as Map<String, dynamic>,
        ),
  devices: (json['devices'] as List<dynamic>)
      .map((e) => Devices.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StaffProfileToJson(StaffProfile instance) =>
    <String, dynamic>{
      'city': instance.city,
      'city_name': instance.cityName,
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'roles': instance.roles,
      'node': instance.node,
      'driver_id': instance.driverId,
      'carrier_id': instance.carrierId,
      'phone': instance.phone,
      'national_id': instance.nationalId,
      'photo_url': instance.photoUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'personal': instance.personal,
      'driver': instance.driver,
      'current_vehicle': instance.currentVehicle,
      'devices': instance.devices,
    };
