// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'leg.dart';
import 'meta11.dart';

part 'leg_collection.g.dart';

@JsonSerializable()
class LegCollection {
  const LegCollection({required this.data, required this.meta});

  factory LegCollection.fromJson(Map<String, Object?> json) =>
      _$LegCollectionFromJson(json);

  final List<Leg> data;
  final Meta11 meta;

  Map<String, Object?> toJson() => _$LegCollectionToJson(this);
}
