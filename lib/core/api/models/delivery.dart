// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_status.dart';
import 'failure_reason.dart';
import 'scan_event.dart';

part 'delivery.g.dart';

@JsonSerializable()
class Delivery {
  const Delivery({
    required this.id,
    required this.shipmentId,
    required this.vehicleId,
    required this.status,
    required this.scans,
    this.podConfirmation,
    this.podPhotoUrl,
    this.podPhotoPath,
    this.failureReason,
  });

  factory Delivery.fromJson(Map<String, Object?> json) =>
      _$DeliveryFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final DeliveryStatus status;
  @JsonKey(name: 'pod_confirmation')
  final String? podConfirmation;
  @JsonKey(name: 'pod_photo_url')
  final String? podPhotoUrl;

  /// Referencia durable de la foto en el disco de evidencia (privado)
  @JsonKey(name: 'pod_photo_path')
  final String? podPhotoPath;
  @JsonKey(name: 'failure_reason')
  final FailureReason? failureReason;
  final List<ScanEvent> scans;

  Map<String, Object?> toJson() => _$DeliveryToJson(this);
}
