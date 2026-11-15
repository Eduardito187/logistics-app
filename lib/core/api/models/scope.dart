// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'scope.g.dart';

@JsonSerializable()
class Scope {
  const Scope({this.shipmentIds, this.vehicleId, this.city, this.routeDate});

  factory Scope.fromJson(Map<String, Object?> json) => _$ScopeFromJson(json);

  @JsonKey(name: 'shipment_ids')
  final List<String>? shipmentIds;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  final String? city;
  @JsonKey(name: 'route_date')
  final DateTime? routeDate;

  Map<String, Object?> toJson() => _$ScopeToJson(this);
}
