// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_node.dart';

part 'staff_member.g.dart';

@JsonSerializable()
class StaffMember {
  const StaffMember({
    required this.city,
    required this.cityName,
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.node,
    required this.driverId,
    required this.carrierId,
    required this.phone,
    required this.nationalId,
    required this.photoUrl,
  });

  factory StaffMember.fromJson(Map<String, Object?> json) =>
      _$StaffMemberFromJson(json);

  /// Código del departamento de la persona (la_paz, santa_cruz, …) o null si no tiene ciudad asignada
  final String? city;

  /// Nombre legible de la ciudad, p. ej. La Paz
  @JsonKey(name: 'city_name')
  final String? cityName;
  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final StaffNode? node;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'carrier_id')
  final String? carrierId;

  /// Del perfil de la persona; si falta, de su ficha de chofer
  final String? phone;
  @JsonKey(name: 'national_id')
  final String? nationalId;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  Map<String, Object?> toJson() => _$StaffMemberToJson(this);
}
