// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_owner_type.dart';

part 'fleet_register_document_data.g.dart';

@JsonSerializable()
class FleetRegisterDocumentData {
  const FleetRegisterDocumentData({
    this.status,
    this.ownerType,
    this.ownerId,
    this.documentType,
  });

  factory FleetRegisterDocumentData.fromJson(Map<String, Object?> json) =>
      _$FleetRegisterDocumentDataFromJson(json);

  final String? status;
  @JsonKey(name: 'owner_type')
  final DocumentOwnerType? ownerType;
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  @JsonKey(name: 'document_type')
  final String? documentType;

  Map<String, Object?> toJson() => _$FleetRegisterDocumentDataToJson(this);
}
