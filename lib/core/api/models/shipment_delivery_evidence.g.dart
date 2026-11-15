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
);

Map<String, dynamic> _$ShipmentDeliveryEvidenceToJson(
  ShipmentDeliveryEvidence instance,
) => <String, dynamic>{
  'signature': instance.signature,
  'photo': instance.photo,
  'document': instance.document,
};
