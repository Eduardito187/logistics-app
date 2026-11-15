// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'days.g.dart';

@JsonSerializable()
class Days {
  const Days({
    this.date,
    this.municipalityId,
    this.blocked,
    this.reason,
    this.withinHorizon,
    this.activeUntil,
    this.available,
  });

  factory Days.fromJson(Map<String, Object?> json) => _$DaysFromJson(json);

  final DateTime? date;
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;
  final bool? blocked;
  final String? reason;

  /// Hay cupos activados hasta esa fecha
  @JsonKey(name: 'within_horizon')
  final bool? withinHorizon;
  @JsonKey(name: 'active_until')
  final DateTime? activeUntil;

  /// No bloqueado y dentro del horizonte activo
  final bool? available;

  Map<String, Object?> toJson() => _$DaysToJson(this);
}
