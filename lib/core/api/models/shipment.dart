// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'address_confidence_level.dart';
import 'order_source.dart';
import 'shipment_line.dart';
import 'shipment_status.dart';

part 'shipment.g.dart';

@JsonSerializable()
class Shipment {
  const Shipment({
    required this.id,
    required this.source,
    required this.externalId,
    required this.customerName,
    required this.addressText,
    required this.addressConfidenceScore,
    required this.addressConfidenceLevel,
    required this.status,
    required this.lines,
    this.customerDocumentId,
    this.customerPhone,
    this.customerEmail,
    this.addressReference,
    this.lat,
    this.lng,
  });

  factory Shipment.fromJson(Map<String, Object?> json) =>
      _$ShipmentFromJson(json);

  final String id;
  final OrderSource source;
  @JsonKey(name: 'external_id')
  final String externalId;
  @JsonKey(name: 'customer_name')
  final String customerName;

  /// Customer identity document (CI / NIT)
  @JsonKey(name: 'customer_document_id')
  final String? customerDocumentId;
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;
  @JsonKey(name: 'customer_email')
  final String? customerEmail;
  @JsonKey(name: 'address_text')
  final String addressText;
  @JsonKey(name: 'address_reference')
  final String? addressReference;
  final double? lat;
  final double? lng;
  @JsonKey(name: 'address_confidence_score')
  final int addressConfidenceScore;
  @JsonKey(name: 'address_confidence_level')
  final AddressConfidenceLevel addressConfidenceLevel;
  final ShipmentStatus status;
  final List<ShipmentLine> lines;

  Map<String, Object?> toJson() => _$ShipmentToJson(this);
}
