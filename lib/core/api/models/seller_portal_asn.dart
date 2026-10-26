// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_portal_asn_status.dart';

part 'seller_portal_asn.g.dart';

@JsonSerializable()
class SellerPortalAsn {
  const SellerPortalAsn({
    required this.id,
    required this.sellerId,
    required this.warehouseId,
    required this.status,
    this.appointmentDate,
    this.appointmentStart,
    this.appointmentEnd,
  });

  factory SellerPortalAsn.fromJson(Map<String, Object?> json) =>
      _$SellerPortalAsnFromJson(json);

  final String id;
  @JsonKey(name: 'seller_id')
  final String sellerId;
  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  final SellerPortalAsnStatus status;
  @JsonKey(name: 'appointment_date')
  final DateTime? appointmentDate;
  @JsonKey(name: 'appointment_start')
  final String? appointmentStart;
  @JsonKey(name: 'appointment_end')
  final String? appointmentEnd;

  Map<String, Object?> toJson() => _$SellerPortalAsnToJson(this);
}
