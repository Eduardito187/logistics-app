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
  reference: json['reference'] as String,
  scans: (json['scans'] as List<dynamic>)
      .map((e) => ScanEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  shortAddress: json['short_address'] as String?,
  unitsTotal: (json['units_total'] as num?)?.toInt(),
  unitIds: (json['unit_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  unitsLoaded: (json['units_loaded'] as num?)?.toInt(),
  unitsDelivered: (json['units_delivered'] as num?)?.toInt(),
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String?,
  address: json['address'] as String?,
  podConfirmation: json['pod_confirmation'] as String?,
  podPhotoUrl: json['pod_photo_url'] as String?,
  podPhotoPath: json['pod_photo_path'] as String?,
  podPhotoPaths: (json['pod_photo_paths'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  evidence: (json['evidence'] as List<dynamic>?)
      ?.map((e) => DeliveryEvidenceFile.fromJson(e as Map<String, dynamic>))
      .toList(),
  storeDroppedAt: json['store_dropped_at'] == null
      ? null
      : DateTime.parse(json['store_dropped_at'] as String),
  storeDropNodeId: json['store_drop_node_id'] as String?,
  podPhotoPending: json['pod_photo_pending'] as bool?,
  failureReason: json['failure_reason'] == null
      ? null
      : FailureReason.fromJson(json['failure_reason'] as String),
);

Map<String, dynamic> _$DeliveryToJson(Delivery instance) => <String, dynamic>{
  'short_address': instance.shortAddress,
  'units_total': instance.unitsTotal,
  'unit_ids': instance.unitIds,
  'units_loaded': instance.unitsLoaded,
  'units_delivered': instance.unitsDelivered,
  'id': instance.id,
  'shipment_id': instance.shipmentId,
  'vehicle_id': instance.vehicleId,
  'status': instance.status,
  'reference': instance.reference,
  'order_reference': instance.orderReference,
  'customer_name': instance.customerName,
  'address': instance.address,
  'pod_confirmation': instance.podConfirmation,
  'pod_photo_url': instance.podPhotoUrl,
  'pod_photo_path': instance.podPhotoPath,
  'pod_photo_paths': instance.podPhotoPaths,
  'evidence': instance.evidence,
  'store_dropped_at': instance.storeDroppedAt?.toIso8601String(),
  'store_drop_node_id': instance.storeDropNodeId,
  'pod_photo_pending': instance.podPhotoPending,
  'failure_reason': instance.failureReason,
  'scans': instance.scans,
};
