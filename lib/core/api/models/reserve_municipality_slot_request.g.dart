// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserve_municipality_slot_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReserveMunicipalitySlotRequest _$ReserveMunicipalitySlotRequestFromJson(
  Map<String, dynamic> json,
) => ReserveMunicipalitySlotRequest(
  shipmentId: json['shipment_id'] as String,
  date: DateTime.parse(json['date'] as String),
  windowStart: json['window_start'] as String,
  windowEnd: json['window_end'] as String,
  municipalityId: json['municipality_id'] as String?,
  latitude: json['latitude'] as num?,
  longitude: json['longitude'] as num?,
);

Map<String, dynamic> _$ReserveMunicipalitySlotRequestToJson(
  ReserveMunicipalitySlotRequest instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'date': instance.date.toIso8601String(),
  'window_start': instance.windowStart,
  'window_end': instance.windowEnd,
  'municipality_id': instance.municipalityId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
