// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'odometer_reading.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OdometerReading _$OdometerReadingFromJson(Map<String, dynamic> json) =>
    OdometerReading(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      km: (json['km'] as num).toInt(),
      source: OdometerReadingSource.fromJson(json['source'] as String),
      readAt: DateTime.parse(json['read_at'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$OdometerReadingToJson(OdometerReading instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'km': instance.km,
      'source': instance.source,
      'read_at': instance.readAt.toIso8601String(),
      'note': instance.note,
    };
