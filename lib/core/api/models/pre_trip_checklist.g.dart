// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pre_trip_checklist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreTripChecklist _$PreTripChecklistFromJson(Map<String, dynamic> json) =>
    PreTripChecklist(
      id: json['id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      driverId: json['driver_id'] as String?,
      items: (json['items'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ),
      passed: json['passed'] as bool?,
      pending: (json['pending'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      performedOn: json['performed_on'] == null
          ? null
          : DateTime.parse(json['performed_on'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PreTripChecklistToJson(PreTripChecklist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'driver_id': instance.driverId,
      'items': instance.items,
      'passed': instance.passed,
      'pending': instance.pending,
      'performed_on': instance.performedOn?.toIso8601String(),
      'notes': instance.notes,
    };
