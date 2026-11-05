// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destinations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Destinations _$DestinationsFromJson(Map<String, dynamic> json) => Destinations(
  shipmentReference: json['shipment_reference'] as String?,
  destination: DispatchDestination.fromJson(
    json['destination'] as Map<String, dynamic>,
  ),
  lineCount: (json['line_count'] as num).toInt(),
);

Map<String, dynamic> _$DestinationsToJson(Destinations instance) =>
    <String, dynamic>{
      'shipment_reference': instance.shipmentReference,
      'destination': instance.destination,
      'line_count': instance.lineCount,
    };
