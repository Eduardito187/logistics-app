// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'available_to_promise.g.dart';

@JsonSerializable()
class AvailableToPromise {
  const AvailableToPromise({
    required this.warehouseId,
    required this.sku,
    required this.ownerPartyId,
    required this.availableToPromise,
  });

  factory AvailableToPromise.fromJson(Map<String, Object?> json) =>
      _$AvailableToPromiseFromJson(json);

  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  final String sku;
  @JsonKey(name: 'owner_party_id')
  final String? ownerPartyId;
  @JsonKey(name: 'available_to_promise')
  final int availableToPromise;

  Map<String, Object?> toJson() => _$AvailableToPromiseToJson(this);
}
