// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Delivery _$DeliveryFromJson(Map<String, dynamic> json) => Delivery(
  id: json['id'] as String,
  shipmentId: json['shipment_id'] as String,
  vehicleId: json['vehicle_id'] as String,
  status: DeliveryStatus.fromJson(json['status'] as String),
  scans: (json['scans'] as List<dynamic>)
      .map((e) => ScanEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  podConfirmation: json['pod_confirmation'] as String?,
  podPhotoUrl: json['pod_photo_url'] as String?,
  podPhotoPath: json['pod_photo_path'] as String?,
  failureReason: json['failure_reason'] == null
      ? null
      : FailureReason.fromJson(json['failure_reason'] as String),
);

Map<String, dynamic> _$DeliveryToJson(Delivery instance) => <String, dynamic>{
  'id': instance.id,
  'shipment_id': instance.shipmentId,
  'vehicle_id': instance.vehicleId,
  'status': instance.status,
  'pod_confirmation': instance.podConfirmation,
  'pod_photo_url': instance.podPhotoUrl,
  'pod_photo_path': instance.podPhotoPath,
  'failure_reason': instance.failureReason,
  'scans': instance.scans,
};
