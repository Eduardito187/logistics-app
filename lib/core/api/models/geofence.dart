// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'geo_point.dart';
import 'geofence_type.dart';

part 'geofence.g.dart';

/// Una geocerca (polígono) con su tipo y estado.
@JsonSerializable()
class Geofence {
  const Geofence({
    required this.id,
    required this.name,
    required this.type,
    required this.polygon,
    required this.active,
    this.nodeRef,
  });

  factory Geofence.fromJson(Map<String, Object?> json) =>
      _$GeofenceFromJson(json);

  final String id;
  final String name;
  final GeofenceType type;
  final List<GeoPoint> polygon;
  final bool active;
  @JsonKey(name: 'node_ref')
  final String? nodeRef;

  Map<String, Object?> toJson() => _$GeofenceToJson(this);
}
