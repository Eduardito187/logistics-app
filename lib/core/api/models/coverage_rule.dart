// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'time_window.dart';

part 'coverage_rule.g.dart';

/// Reglas de operación de la zona (CoverageRule). No incluye cupos ni capacidad.
@JsonSerializable()
class CoverageRule {
  const CoverageRule({
    required this.nodeId,
    required this.services,
    required this.baseMinutes,
    required this.productLimits,
    required this.timeWindows,
    required this.serviceDays,
  });

  factory CoverageRule.fromJson(Map<String, Object?> json) =>
      _$CoverageRuleFromJson(json);

  /// Nodo de la red que atiende la zona.
  final String? nodeId;
  final List<String> services;

  /// Tiempo base de preparación/entrega en minutos.
  final int baseMinutes;

  /// Límite de unidades por SKU.
  final Map<String, int> productLimits;
  final List<TimeWindow> timeWindows;

  /// Días de atención (1=lunes .. 7=domingo).
  final List<int> serviceDays;

  Map<String, Object?> toJson() => _$CoverageRuleToJson(this);
}
