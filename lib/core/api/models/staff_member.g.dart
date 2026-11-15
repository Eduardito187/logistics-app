// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffMember _$StaffMemberFromJson(Map<String, dynamic> json) => StaffMember(
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
);

Map<String, dynamic> _$StaffMemberToJson(StaffMember instance) =>
    <String, dynamic>{
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
    };
