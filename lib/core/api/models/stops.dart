// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'stops.g.dart';

@JsonSerializable()
class Stops {
  const Stops({
    required this.shipmentId,
    required this.sequence,
    this.orderReference,
    this.customerName,
    this.address,
    this.etaAt,
    this.lat,
    this.lng,
  });

  factory Stops.fromJson(Map<String, Object?> json) => _$StopsFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final int sequence;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  final String? address;
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;
  final double? lat;
  final double? lng;

  Map<String, Object?> toJson() => _$StopsToJson(this);
}
