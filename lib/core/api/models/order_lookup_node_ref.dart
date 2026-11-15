// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'order_lookup_node_ref.g.dart';

@JsonSerializable()
class OrderLookupNodeRef {
  const OrderLookupNodeRef({required this.id, required this.name});

  factory OrderLookupNodeRef.fromJson(Map<String, Object?> json) =>
      _$OrderLookupNodeRefFromJson(json);

  final String id;
  final String? name;

  Map<String, Object?> toJson() => _$OrderLookupNodeRefToJson(this);
}
