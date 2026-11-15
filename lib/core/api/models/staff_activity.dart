// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_activity_type.dart';

part 'staff_activity.g.dart';

@JsonSerializable()
class StaffActivity {
  const StaffActivity({this.type, this.at, this.title, this.detail});

  factory StaffActivity.fromJson(Map<String, Object?> json) =>
      _$StaffActivityFromJson(json);

  final StaffActivityType? type;
  final DateTime? at;

  /// Código estable: tipo de escaneo, vehicle_assigned, checklist_passed, checklist_failed, device_last_seen
  final String? title;

  /// Pedido, placa o dispositivo, según el tipo
  final String? detail;

  Map<String, Object?> toJson() => _$StaffActivityToJson(this);
}
