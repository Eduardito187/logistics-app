// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'delivery_calendar_municipality.g.dart';

@JsonSerializable()
class DeliveryCalendarMunicipality {
  const DeliveryCalendarMunicipality({
    required this.id,
    required this.name,
    required this.label,
    this.departmentId,
    this.departmentName,
  });

  factory DeliveryCalendarMunicipality.fromJson(Map<String, Object?> json) =>
      _$DeliveryCalendarMunicipalityFromJson(json);

  final String id;
  final String name;
  @JsonKey(name: 'department_id')
  final String? departmentId;
  @JsonKey(name: 'department_name')
  final String? departmentName;

  /// Etiqueta legible: municipio y departamento
  final String label;

  Map<String, Object?> toJson() => _$DeliveryCalendarMunicipalityToJson(this);
}
