// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_document.dart';

part 'register_carrier_request.g.dart';

@JsonSerializable()
class RegisterCarrierRequest {
  const RegisterCarrierRequest({
    required this.name,
    required this.taxId,
    this.documents,
  });

  factory RegisterCarrierRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterCarrierRequestFromJson(json);

  final String name;
  @JsonKey(name: 'tax_id')
  final String taxId;
  final List<CarrierDocument>? documents;

  Map<String, Object?> toJson() => _$RegisterCarrierRequestToJson(this);
}
