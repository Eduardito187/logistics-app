// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_line.dart';
import 'return_order_kind.dart';

part 'initiate_return_request.g.dart';

@JsonSerializable()
class InitiateReturnRequest {
  const InitiateReturnRequest({
    required this.originalReference,
    required this.warehouseId,
    required this.kind,
    required this.lines,
    this.ownerPartyId,
  });

  factory InitiateReturnRequest.fromJson(Map<String, Object?> json) =>
      _$InitiateReturnRequestFromJson(json);

  @JsonKey(name: 'original_reference')
  final String originalReference;
  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  final ReturnOrderKind kind;

  /// Seller dueño del inventario; nulo para inventario propio.
  @JsonKey(name: 'owner_party_id')
  final String? ownerPartyId;
  final List<ReturnLine> lines;

  Map<String, Object?> toJson() => _$InitiateReturnRequestToJson(this);
}
