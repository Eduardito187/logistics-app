// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_product_media.g.dart';

@JsonSerializable()
class CommerceProductMedia {
  const CommerceProductMedia({
    required this.path,
    required this.alt,
    required this.position,
  });

  factory CommerceProductMedia.fromJson(Map<String, Object?> json) =>
      _$CommerceProductMediaFromJson(json);

  final String path;
  final String alt;
  final int position;

  Map<String, Object?> toJson() => _$CommerceProductMediaToJson(this);
}
