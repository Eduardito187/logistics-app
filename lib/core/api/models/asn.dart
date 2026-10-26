// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'asn_appointment.dart';
import 'asn_line.dart';
import 'asn_status.dart';

part 'asn.g.dart';

@JsonSerializable()
class Asn {
  const Asn({
    required this.id,
    required this.sellerId,
    required this.warehouseId,
    required this.status,
    required this.lines,
    required this.appointment,
  });

  factory Asn.fromJson(Map<String, Object?> json) => _$AsnFromJson(json);

  final String id;
  @JsonKey(name: 'seller_id')
  final String sellerId;
  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  final AsnStatus status;
  final List<AsnLine> lines;
  final AsnAppointment? appointment;

  Map<String, Object?> toJson() => _$AsnToJson(this);
}
