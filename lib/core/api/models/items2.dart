// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'items2.g.dart';

@JsonSerializable()
class Items2 {
  const Items2({required this.name, required this.qty});

  factory Items2.fromJson(Map<String, Object?> json) => _$Items2FromJson(json);

  final String name;
  final int qty;

  Map<String, Object?> toJson() => _$Items2ToJson(this);
}
