// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_owner_type.dart';

part 'data15.g.dart';

@JsonSerializable()
class Data15 {
  const Data15({this.status, this.ownerType, this.ownerId, this.documentType});

  factory Data15.fromJson(Map<String, Object?> json) => _$Data15FromJson(json);

  final String? status;
  @JsonKey(name: 'owner_type')
  final DocumentOwnerType? ownerType;
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  @JsonKey(name: 'document_type')
  final String? documentType;

  Map<String, Object?> toJson() => _$Data15ToJson(this);
}
