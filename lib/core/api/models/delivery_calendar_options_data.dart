// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_activation_window.dart';
import 'delivery_calendar_municipality.dart';
import 'delivery_calendar_unit_option.dart';

part 'delivery_calendar_options_data.g.dart';

@JsonSerializable()
class DeliveryCalendarOptionsData {
  const DeliveryCalendarOptionsData({
    required this.municipalities,
    required this.timeSlots,
    required this.timeSlotFormat,
    required this.units,
    required this.defaultWindows,
    required this.weekdays,
    required this.serviceDays,
  });

  factory DeliveryCalendarOptionsData.fromJson(Map<String, Object?> json) =>
      _$DeliveryCalendarOptionsDataFromJson(json);

  final List<DeliveryCalendarMunicipality> municipalities;

  /// Franjas que ofrecen las reglas de cupo (por defecto y por día de la semana)
  @JsonKey(name: 'time_slots')
  final List<String> timeSlots;
  @JsonKey(name: 'time_slot_format')
  final String timeSlotFormat;
  final List<DeliveryCalendarUnitOption> units;

  /// Ventanas por defecto de las reglas; vacío si las reglas no definen ninguna
  @JsonKey(name: 'default_windows')
  final List<DeliveryCalendarActivationWindow> defaultWindows;

  /// 1 = lunes … 7 = domingo
  final List<int> weekdays;

  /// Días de servicio de las reglas (sugerencia para preseleccionar)
  @JsonKey(name: 'service_days')
  final List<int> serviceDays;

  Map<String, Object?> toJson() => _$DeliveryCalendarOptionsDataToJson(this);
}
