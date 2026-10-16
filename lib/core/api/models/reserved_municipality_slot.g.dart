// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserved_municipality_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReservedMunicipalitySlot _$ReservedMunicipalitySlotFromJson(
  Map<String, dynamic> json,
) => ReservedMunicipalitySlot(
  shipmentId: json['shipment_id'] as String,
  deliveryDate: DateTime.parse(json['delivery_date'] as String),
  deliveryWindowStart: json['delivery_window_start'] as String,
  deliveryWindowEnd: json['delivery_window_end'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$ReservedMunicipalitySlotToJson(
  ReservedMunicipalitySlot instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'delivery_date': instance.deliveryDate.toIso8601String(),
  'delivery_window_start': instance.deliveryWindowStart,
  'delivery_window_end': instance.deliveryWindowEnd,
  'status': instance.status,
};
