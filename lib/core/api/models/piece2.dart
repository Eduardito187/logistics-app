// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'piece2.g.dart';

@JsonSerializable()
class Piece2 {
  const Piece2({this.index, this.total});

  factory Piece2.fromJson(Map<String, Object?> json) => _$Piece2FromJson(json);

  final int? index;
  final int? total;

  Map<String, Object?> toJson() => _$Piece2ToJson(this);
}
