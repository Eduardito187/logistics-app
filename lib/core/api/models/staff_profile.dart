// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'current_vehicle.dart';
import 'devices.dart';
import 'staff_driver_data.dart';
import 'staff_node.dart';
import 'staff_personal_data.dart';

part 'staff_profile.g.dart';

@JsonSerializable()
class StaffProfile {
  const StaffProfile({
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
    required this.createdAt,
    required this.personal,
    required this.driver,
    required this.currentVehicle,
    required this.devices,
  });

  factory StaffProfile.fromJson(Map<String, Object?> json) =>
      _$StaffProfileFromJson(json);

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
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  final StaffPersonalData personal;
  final StaffDriverData? driver;

  /// Vehículo vigente del chofer (su tripulación de hoy o la última anterior)
  @JsonKey(name: 'current_vehicle')
  final CurrentVehicle? currentVehicle;
  final List<Devices> devices;

  Map<String, Object?> toJson() => _$StaffProfileToJson(this);
}
