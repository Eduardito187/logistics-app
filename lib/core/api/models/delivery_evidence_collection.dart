// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_evidence.dart';

part 'delivery_evidence_collection.g.dart';

@JsonSerializable()
class DeliveryEvidenceCollection {
  const DeliveryEvidenceCollection({required this.data});

  factory DeliveryEvidenceCollection.fromJson(Map<String, Object?> json) =>
      _$DeliveryEvidenceCollectionFromJson(json);

  final List<DeliveryEvidence> data;

  Map<String, Object?> toJson() => _$DeliveryEvidenceCollectionToJson(this);
}
