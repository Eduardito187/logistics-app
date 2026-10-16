// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meta14.dart';
import 'operational_corridor.dart';

part 'operational_corridor_collection.g.dart';

@JsonSerializable()
class OperationalCorridorCollection {
  const OperationalCorridorCollection({required this.data, required this.meta});

  factory OperationalCorridorCollection.fromJson(Map<String, Object?> json) =>
      _$OperationalCorridorCollectionFromJson(json);

  final List<OperationalCorridor> data;
  final Meta14 meta;

  Map<String, Object?> toJson() => _$OperationalCorridorCollectionToJson(this);
}
