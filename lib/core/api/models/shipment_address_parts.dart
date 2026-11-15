// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shipment_address_parts.g.dart';

/// Best-effort parse of the free-text address (no ingest source sends a structured address yet).
@JsonSerializable()
class ShipmentAddressParts {
  const ShipmentAddressParts({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.reference,
    required this.city,
  });

  factory ShipmentAddressParts.fromJson(Map<String, Object?> json) =>
      _$ShipmentAddressPartsFromJson(json);

  final String? street;
  final String? number;
  final String? neighborhood;
  final String? reference;
  final String? city;

  Map<String, Object?> toJson() => _$ShipmentAddressPartsToJson(this);
}
