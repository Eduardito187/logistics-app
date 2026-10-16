// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meta13.dart';
import 'node.dart';

part 'node_collection.g.dart';

@JsonSerializable()
class NodeCollection {
  const NodeCollection({required this.data, required this.meta});

  factory NodeCollection.fromJson(Map<String, Object?> json) =>
      _$NodeCollectionFromJson(json);

  final List<Node> data;
  final Meta13 meta;

  Map<String, Object?> toJson() => _$NodeCollectionToJson(this);
}
