// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier_trip_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarrierTripState _$CarrierTripStateFromJson(Map<String, dynamic> json) =>
    CarrierTripState(
      tripId: json['trip_id'] as String,
      carrierId: json['carrier_id'] as String,
      status: CarrierTripStatus.fromJson(json['status'] as String),
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      shipmentsCount: (json['shipments_count'] as num).toInt(),
      reference: json['reference'] as String?,
    );

Map<String, dynamic> _$CarrierTripStateToJson(CarrierTripState instance) =>
    <String, dynamic>{
      'trip_id': instance.tripId,
      'carrier_id': instance.carrierId,
      'reference': instance.reference,
      'status': instance.status,
      'scheduled_at': instance.scheduledAt.toIso8601String(),
      'started_at': instance.startedAt?.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'shipments_count': instance.shipmentsCount,
    };
