// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reserved_municipality_slot.g.dart';

@JsonSerializable()
class ReservedMunicipalitySlot {
  const ReservedMunicipalitySlot({
    required this.shipmentId,
    required this.deliveryDate,
    required this.deliveryWindowStart,
    required this.deliveryWindowEnd,
    required this.status,
  });

  factory ReservedMunicipalitySlot.fromJson(Map<String, Object?> json) =>
      _$ReservedMunicipalitySlotFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'delivery_date')
  final DateTime deliveryDate;
  @JsonKey(name: 'delivery_window_start')
  final String deliveryWindowStart;
  @JsonKey(name: 'delivery_window_end')
  final String deliveryWindowEnd;
  final String status;

  Map<String, Object?> toJson() => _$ReservedMunicipalitySlotToJson(this);
}
