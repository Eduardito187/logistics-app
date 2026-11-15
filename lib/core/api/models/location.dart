// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location {
  const Location({this.lat, this.lng});

  factory Location.fromJson(Map<String, Object?> json) =>
      _$LocationFromJson(json);

  final num? lat;
  final num? lng;

  Map<String, Object?> toJson() => _$LocationToJson(this);
}
