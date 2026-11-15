// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_lookup_match.dart';

part 'order_lookup_meta.g.dart';

@JsonSerializable()
class OrderLookupMeta {
  const OrderLookupMeta({
    required this.count,
    required this.matchedBy,
    required this.matchedShipmentId,
  });

  factory OrderLookupMeta.fromJson(Map<String, Object?> json) =>
      _$OrderLookupMetaFromJson(json);

  final int count;
  @JsonKey(name: 'matched_by')
  final OrderLookupMatch matchedBy;

  /// Solo cuando se encontró por etiqueta: el envío al que pertenece la etiqueta escaneada.
  @JsonKey(name: 'matched_shipment_id')
  final String? matchedShipmentId;

  Map<String, Object?> toJson() => _$OrderLookupMetaToJson(this);
}
