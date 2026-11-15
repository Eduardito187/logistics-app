// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripCandidate _$TripCandidateFromJson(
  Map<String, dynamic> json,
) => TripCandidate(
  shipmentId: json['shipment_id'] as String,
  unitsTotal: (json['units_total'] as num).toInt(),
  fits: json['fits'] as bool,
  suggested: json['suggested'] as bool,
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String?,
  shortAddress: json['short_address'] as String?,
  deliveryMode: json['delivery_mode'] == null
      ? null
      : DeliveryMode.fromJson(json['delivery_mode'] as String),
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  distanceKmFromAnchor: (json['distance_km_from_anchor'] as num?)?.toDouble(),
  timeWindow: json['time_window'] == null
      ? null
      : StopTimeWindow.fromJson(json['time_window'] as Map<String, dynamic>),
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
  volumeM3: (json['volume_m3'] as num?)?.toDouble(),
  fitsReason: json['fits_reason'] as String?,
  suggestedReason: json['suggested_reason'] as String?,
);

Map<String, dynamic> _$TripCandidateToJson(TripCandidate instance) =>
    <String, dynamic>{
      'shipment_id': instance.shipmentId,
      'order_reference': instance.orderReference,
      'customer_name': instance.customerName,
      'short_address': instance.shortAddress,
      'delivery_mode': instance.deliveryMode,
      'units_total': instance.unitsTotal,
      'lat': instance.lat,
      'lng': instance.lng,
      'distance_km_from_anchor': instance.distanceKmFromAnchor,
      'time_window': instance.timeWindow,
      'weight_kg': instance.weightKg,
      'volume_m3': instance.volumeM3,
      'fits': instance.fits,
      'fits_reason': instance.fitsReason,
      'suggested': instance.suggested,
      'suggested_reason': instance.suggestedReason,
    };
