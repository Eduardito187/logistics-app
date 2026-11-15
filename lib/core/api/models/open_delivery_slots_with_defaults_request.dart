// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'open_delivery_slots_with_defaults_request.g.dart';

/// Se envía date (un solo día) o from + to (rango); no ambos.
@JsonSerializable()
class OpenDeliverySlotsWithDefaultsRequest {
  const OpenDeliverySlotsWithDefaultsRequest({
    this.date,
    this.from,
    this.to,
    this.municipalityIds,
    this.weekdays,
  });

  factory OpenDeliverySlotsWithDefaultsRequest.fromJson(
    Map<String, Object?> json,
  ) => _$OpenDeliverySlotsWithDefaultsRequestFromJson(json);

  /// Un solo día; excluye from y to
  final DateTime? date;

  /// Inicio del rango; requiere to
  final DateTime? from;

  /// Fin del rango; igual o posterior a from
  final DateTime? to;

  /// Opcional. Ausente o vacío = los municipios del catálogo completo
  @JsonKey(name: 'municipality_ids')
  final List<String>? municipalityIds;

  /// Opcional. 1 = lunes … 7 = domingo. Ausente o vacío = los siete días
  final List<int>? weekdays;

  Map<String, Object?> toJson() =>
      _$OpenDeliverySlotsWithDefaultsRequestToJson(this);
}
