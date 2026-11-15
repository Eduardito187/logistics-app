// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_evidence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryEvidence _$DeliveryEvidenceFromJson(Map<String, dynamic> json) =>
    DeliveryEvidence(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      kind: DeliveryEvidenceKind.fromJson(json['kind'] as String),
      validationStatus: DeliveryEvidenceValidationStatus.fromJson(
        json['validation_status'] as String,
      ),
      sha256: json['sha256'] as String,
      storage: Storage.fromJson(json['storage'] as Map<String, dynamic>),
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      url: json['url'] as String?,
      validationDetail: json['validation_detail'] as String?,
      capturedAt: json['captured_at'] == null
          ? null
          : DateTime.parse(json['captured_at'] as String),
      validatedAt: json['validated_at'] == null
          ? null
          : DateTime.parse(json['validated_at'] as String),
    );

Map<String, dynamic> _$DeliveryEvidenceToJson(DeliveryEvidence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shipment_id': instance.shipmentId,
      'kind': instance.kind,
      'url': instance.url,
      'validation_status': instance.validationStatus,
      'validation_detail': instance.validationDetail,
      'sha256': instance.sha256,
      'storage': instance.storage,
      'customer': instance.customer,
      'location': instance.location,
      'captured_at': instance.capturedAt?.toIso8601String(),
      'validated_at': instance.validatedAt?.toIso8601String(),
    };
