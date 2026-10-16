// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'items.g.dart';

@JsonSerializable()
class Items {
  const Items({required this.name, required this.qty});

  factory Items.fromJson(Map<String, Object?> json) => _$ItemsFromJson(json);

  final String name;
  final int qty;

  Map<String, Object?> toJson() => _$ItemsToJson(this);
}
