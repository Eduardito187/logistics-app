// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_source.dart';
import 'receive_shipment_line.dart';

part 'receive_shipment_request.g.dart';

@JsonSerializable()
class ReceiveShipmentRequest {
  const ReceiveShipmentRequest({
    required this.source,
    required this.externalId,
    required this.customerName,
    required this.addressText,
    required this.lines,
    this.customerDocumentId,
    this.customerPhone,
    this.customerEmail,
    this.addressReference,
    this.lat,
    this.lng,
  });

  factory ReceiveShipmentRequest.fromJson(Map<String, Object?> json) =>
      _$ReceiveShipmentRequestFromJson(json);

  final OrderSource source;

  /// External reference of the order in its source system
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
  final List<ReceiveShipmentLine> lines;

  Map<String, Object?> toJson() => _$ReceiveShipmentRequestToJson(this);
}
