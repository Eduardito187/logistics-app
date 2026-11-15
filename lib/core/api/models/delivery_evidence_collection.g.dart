// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_evidence_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryEvidenceCollection _$DeliveryEvidenceCollectionFromJson(
  Map<String, dynamic> json,
) => DeliveryEvidenceCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => DeliveryEvidence.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DeliveryEvidenceCollectionToJson(
  DeliveryEvidenceCollection instance,
) => <String, dynamic>{'data': instance.data};
