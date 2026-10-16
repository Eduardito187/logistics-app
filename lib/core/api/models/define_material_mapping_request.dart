// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'define_material_mapping_request.g.dart';

@JsonSerializable()
class DefineMaterialMappingRequest {
  const DefineMaterialMappingRequest({
    required this.sku,
    required this.material,
    required this.center,
    required this.warehouse,
  });

  factory DefineMaterialMappingRequest.fromJson(Map<String, Object?> json) =>
      _$DefineMaterialMappingRequestFromJson(json);

  /// SKU propio de la plataforma
  final String sku;

  /// Material SAP
  final String material;

  /// Centro SAP
  final String center;

  /// Almacén SAP
  final String warehouse;

  Map<String, Object?> toJson() => _$DefineMaterialMappingRequestToJson(this);
}
