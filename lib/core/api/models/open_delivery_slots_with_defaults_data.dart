// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_activation_window.dart';
import 'open_delivery_slots_with_defaults_data_status.dart';

part 'open_delivery_slots_with_defaults_data.g.dart';

@JsonSerializable()
class OpenDeliverySlotsWithDefaultsData {
  const OpenDeliverySlotsWithDefaultsData({
    required this.status,
    required this.from,
    required this.to,
    required this.weekdays,
    required this.allMunicipalities,
    required this.municipalitiesCount,
    required this.municipalityIds,
    required this.windows,
  });

  factory OpenDeliverySlotsWithDefaultsData.fromJson(
    Map<String, Object?> json,
  ) => _$OpenDeliverySlotsWithDefaultsDataFromJson(json);

  final OpenDeliverySlotsWithDefaultsDataStatus status;
  final DateTime from;
  final DateTime to;
  final List<int> weekdays;
  @JsonKey(name: 'all_municipalities')
  final bool allMunicipalities;
  @JsonKey(name: 'municipalities_count')
  final int municipalitiesCount;
  @JsonKey(name: 'municipality_ids')
  final List<String> municipalityIds;

  /// Ventanas por defecto que se usaron
  final List<DeliveryCalendarActivationWindow> windows;

  Map<String, Object?> toJson() =>
      _$OpenDeliverySlotsWithDefaultsDataToJson(this);
}
