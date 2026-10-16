// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'close_departure_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CloseDepartureRequest _$CloseDepartureRequestFromJson(
  Map<String, dynamic> json,
) => CloseDepartureRequest(
  odometerInKm: (json['odometer_in_km'] as num).toInt(),
  returnedAt: DateTime.parse(json['returned_at'] as String),
);

Map<String, dynamic> _$CloseDepartureRequestToJson(
  CloseDepartureRequest instance,
) => <String, dynamic>{
  'odometer_in_km': instance.odometerInKm,
  'returned_at': instance.returnedAt.toIso8601String(),
};
