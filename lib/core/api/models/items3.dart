// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'items3.g.dart';

@JsonSerializable()
class Items3 {
  const Items3({
    required this.sku,
    required this.name,
    required this.quantity,
    this.imageUrl,
  });

  factory Items3.fromJson(Map<String, Object?> json) => _$Items3FromJson(json);

  final String sku;
  final String name;
  final int quantity;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  Map<String, Object?> toJson() => _$Items3ToJson(this);
}
