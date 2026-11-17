// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_delivery_evidence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentDeliveryEvidence _$ShipmentDeliveryEvidenceFromJson(
  Map<String, dynamic> json,
) => ShipmentDeliveryEvidence(
  signature: json['signature'] as bool,
  photo: json['photo'] as bool,
  document: json['document'] as bool,
  withShortage: json['with_shortage'] as bool,
  missingCount: (json['missing_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$ShipmentDeliveryEvidenceToJson(
  ShipmentDeliveryEvidence instance,
) => <String, dynamic>{
  'signature': instance.signature,
  'photo': instance.photo,
  'document': instance.document,
  'with_shortage': instance.withShortage,
  'missing_count': instance.missingCount,
};
