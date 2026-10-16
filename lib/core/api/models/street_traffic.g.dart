// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'street_traffic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreetTraffic _$StreetTrafficFromJson(Map<String, dynamic> json) =>
    StreetTraffic(
      segmentKey: json['segment_key'] as String,
      geometry: (json['geometry'] as List<dynamic>)
          .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      sampleCount: (json['sample_count'] as num).toInt(),
      avgSpeedKph: (json['avg_speed_kph'] as num).toDouble(),
      minSpeedKph: (json['min_speed_kph'] as num).toDouble(),
      congestionLevel: StreetTrafficCongestionLevel.fromJson(
        json['congestion_level'] as String,
      ),
      hourHistogram: (json['hour_histogram'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$StreetTrafficToJson(StreetTraffic instance) =>
    <String, dynamic>{
      'segment_key': instance.segmentKey,
      'name': instance.name,
      'geometry': instance.geometry,
      'sample_count': instance.sampleCount,
      'avg_speed_kph': instance.avgSpeedKph,
      'min_speed_kph': instance.minSpeedKph,
      'congestion_level': instance.congestionLevel,
      'hour_histogram': instance.hourHistogram,
    };
